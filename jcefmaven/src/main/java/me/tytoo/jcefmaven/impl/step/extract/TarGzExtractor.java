package me.tytoo.jcefmaven.impl.step.extract;

import org.apache.commons.compress.archivers.tar.TarArchiveEntry;
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Class used to extract .tar.gz archives.
 * Preserves executable attributes.
 *
 * @author Fritz Windisch
 */
public class TarGzExtractor {
    private static final int BUFFER_SIZE = 4096;
    private static final Logger LOGGER = Logger.getLogger(TarGzExtractor.class.getName());

    public static void extractTarGZ(File installDir, InputStream in) throws IOException {
        Objects.requireNonNull(installDir, "installDir cannot be null");
        Objects.requireNonNull(in, "in cannot be null");
        Path installPath = installDir.toPath().toAbsolutePath().normalize();
        try (InputStream gzipIn = new GzipCompressorInputStream(in);
             TarArchiveInputStream tarIn = new TarArchiveInputStream(gzipIn)) {
            TarArchiveEntry entry;

            while ((entry = tarIn.getNextTarEntry()) != null) {
                Path target = installPath.resolve(entry.getName()).normalize();
                if (!target.startsWith(installPath)) {
                    throw new IOException("Refusing to write outside installation directory: " + entry.getName());
                }
                if (entry.isDirectory()) {
                    try {
                        Files.createDirectories(target);
                    } catch (IOException e) {
                        LOGGER.log(Level.SEVERE, String.format("Unable to create directory '%s' during extraction.",
                                target), e);
                    }
                    if ((entry.getMode() & 0111) != 0 && !target.toFile().setExecutable(true, false)) {
                        LOGGER.log(Level.SEVERE, String.format("Unable to mark directory '%s' executable during extraction.",
                                target));
                    }
                } else {
                    int count;
                    byte[] data = new byte[BUFFER_SIZE];
                    if (target.getParent() != null) {
                        Files.createDirectories(target.getParent());
                    }
                    try (OutputStream dest = new BufferedOutputStream(
                            Files.newOutputStream(target), BUFFER_SIZE)) {
                        while ((count = tarIn.read(data, 0, BUFFER_SIZE)) != -1) {
                            dest.write(data, 0, count);
                        }
                    }
                    if ((entry.getMode() & 0111) != 0 && !target.toFile().setExecutable(true, false)) {
                        LOGGER.log(Level.SEVERE, String.format("Unable to mark file '%s' executable during extraction.",
                                target));
                    }
                }
            }
        }
    }
}
