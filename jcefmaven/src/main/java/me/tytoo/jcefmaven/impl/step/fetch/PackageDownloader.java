package me.tytoo.jcefmaven.impl.step.fetch;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import me.tytoo.jcefmaven.CefBuildInfo;
import me.tytoo.jcefmaven.EnumPlatform;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.lang.reflect.Type;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Collection;
import java.util.Map;
import java.util.Objects;
import java.util.function.Consumer;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Class used to download the native packages from GitHub or central repository.
 * Central repository is only used as fallback.
 *
 * @author Fritz Windisch
 */
public class PackageDownloader {
    private static final Gson GSON = new Gson();
    private static final Type MAP_TYPE = new TypeToken<Map<String, Object>>() {
    }.getType();
    private static final Logger LOGGER = Logger.getLogger(PackageDownloader.class.getName());
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    private static final int BUFFER_SIZE = 16 * 1024;

    public static void downloadNatives(CefBuildInfo info, EnumPlatform platform, File destination,
                                       Consumer<Float> progressConsumer, Collection<String> mirrors) throws IOException {
        Objects.requireNonNull(info, "info cannot be null");
        Objects.requireNonNull(platform, "platform cannot be null");
        Objects.requireNonNull(destination, "destination cannot be null");
        Objects.requireNonNull(progressConsumer, "progressConsumer cannot be null");
        Objects.requireNonNull(mirrors, "mirrors can not be null");
        if (mirrors.isEmpty()) {
            throw new RuntimeException("mirrors can not be empty");
        }

        Path destinationPath = destination.toPath();
        if (destinationPath.getParent() != null) {
            Files.createDirectories(destinationPath.getParent());
        }

        String mvn_version = loadJCefMavenVersion();

        //Try all mirrors
        Exception lastException = null;
        for (String mirror : mirrors) {
            String m = mirror
                    .replace("{platform}", platform.getIdentifier())
                    .replace("{tag}", info.getReleaseTag())
                    .replace("{mvn_version}", mvn_version);
            try {
                Files.deleteIfExists(destinationPath);
                Files.createFile(destinationPath);
                HttpRequest request = HttpRequest.newBuilder(URI.create(m)).GET().build();
                HttpResponse<InputStream> response = HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofInputStream());
                try (InputStream body = response.body()) {
                    int status = response.statusCode();
                    if (status != 200) {
                        LOGGER.log(Level.WARNING, "Request to mirror failed with code " + status + " from server: " + m);
                        continue;
                    }

                    long length = response.headers().firstValueAsLong("Content-Length").orElse(-1L);
                    if (length <= 0) {
                        progressConsumer.accept(-1f);
                    } else {
                        progressConsumer.accept(0f);
                    }

                    try (InputStream in = new BufferedInputStream(body);
                         OutputStream out = new BufferedOutputStream(
                                 Files.newOutputStream(destinationPath, StandardOpenOption.TRUNCATE_EXISTING), BUFFER_SIZE)) {
                        byte[] buffer = new byte[BUFFER_SIZE];
                        long transferred = 0;
                        float lastProgress = -1f;
                        int r;
                        while ((r = in.read(buffer)) > 0) {
                            out.write(buffer, 0, r);
                            transferred += r;
                            if (length > 0) {
                                float progress = (float) (transferred * 100.0 / length);
                                if (progress - lastProgress >= 1f) {
                                    lastProgress = progress;
                                    progressConsumer.accept(Math.min(progress, 100f));
                                }
                            }
                        }
                        out.flush();
                    }
                }
                return;
            } catch (Exception e) {
                LOGGER.log(Level.WARNING, "Request failed with exception on mirror: " + m, e);
                lastException = e;
                try {
                    Files.deleteIfExists(destinationPath);
                } catch (IOException ignore) {
                    // best-effort cleanup
                }
            }
        }
        //Throw exception if no download was successful
        if (lastException != null) {
            throw new IOException("None of the supplied mirrors were working", lastException);
        } else {
            throw new IOException("None of the supplied mirrors were working");
        }
    }

    private static String loadJCefMavenVersion() throws IOException {
        Map<String, Object> object;
        try (InputStream in = PackageDownloader.class.getResourceAsStream("/jcefmaven_build_meta.json")) {
            if (in == null) {
                throw new IOException("/jcefmaven_build_meta.json not found on class path");
            }
            object = GSON.fromJson(new InputStreamReader(in, StandardCharsets.UTF_8), MAP_TYPE);
        } catch (Exception e) {
            throw new IOException("Invalid json content in jcefmaven_build_meta.json", e);
        }
        return Objects.requireNonNull(object.get("version"), "No version field in jcefmaven_build_meta.json").toString();
    }
}
