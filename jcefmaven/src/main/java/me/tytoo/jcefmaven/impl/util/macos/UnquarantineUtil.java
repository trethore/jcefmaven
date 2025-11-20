package me.tytoo.jcefmaven.impl.util.macos;

import java.io.File;
import java.io.IOException;
import java.util.Objects;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Util used to unquarantine directories recursively on MacOS.
 * Else MacOS would screw the installation.
 *
 * @author Fritz Windisch
 */
public class UnquarantineUtil {
    private static final Logger LOGGER = Logger.getLogger(UnquarantineUtil.class.getName());

    public static void unquarantine(File dir) {
        Objects.requireNonNull(dir, "dir cannot be null");
        ProcessBuilder processBuilder = new ProcessBuilder("xattr", "-r", "-d", "com.apple.quarantine",
                dir.getAbsolutePath());
        processBuilder.redirectErrorStream(true);
        try {
            Process process = processBuilder.start();
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                LOGGER.log(Level.WARNING, "Failed to update xattr! Command returned non-zero exit code: " + exitCode);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            LOGGER.log(Level.WARNING, "Failed to update xattr! Command got interrupted.", e);
        } catch (IOException e) {
            LOGGER.log(Level.WARNING, "Failed to update xattr! IOException on command execution: " + e.getMessage());
        }
    }
}
