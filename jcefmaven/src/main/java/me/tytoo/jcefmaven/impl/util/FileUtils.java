package me.tytoo.jcefmaven.impl.util;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Util providing utils for files.
 *
 * @author Fritz Windisch
 */
public class FileUtils {
    private static final Logger LOGGER = Logger.getLogger(FileUtils.class.getName());

    public static void deleteDir(File dir) {
        Objects.requireNonNull(dir, "dir cannot be null");
        Path directory = dir.toPath();
        if (!Files.exists(directory)) {
            return;
        }
        try (var walk = Files.walk(directory)) {
            walk.sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException e) {
                            LOGGER.log(Level.WARNING, "Could not delete " + path, e);
                        }
                    });
        } catch (IOException e) {
            LOGGER.log(Level.WARNING, "Could not delete " + directory, e);
        }
    }
}
