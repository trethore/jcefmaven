package me.tytoo.jcefmaven.impl.step.init;

import me.tytoo.jcefmaven.CefInitializationException;
import me.tytoo.jcefmaven.EnumPlatform;
import me.tytoo.jcefmaven.UnsupportedPlatformException;
import org.cef.CefApp;
import org.cef.CefSettings;
import org.cef.SystemBootstrap;

import java.io.File;
import java.util.List;
import java.util.Objects;
import java.util.logging.Logger;

/**
 * Platform dependent initialization code for JCef.
 *
 * @author Fritz Windisch
 */
public class CefInitializer {

    private static final Logger LOGGER = Logger.getLogger(CefInitializer.class.getName());

    private static final String JAVA_LIBRARY_PATH = "java.library.path";

    public static CefApp initialize(File installDir, List<String> cefArgs, CefSettings cefSettings) throws UnsupportedPlatformException, CefInitializationException {
        Objects.requireNonNull(installDir, "installDir cannot be null");
        Objects.requireNonNull(cefArgs, "cefArgs cannot be null");
        Objects.requireNonNull(cefSettings, "cefSettings cannot be null");

        try {
            //Patch java library path to scan the install dir of our application
            //This is required for jcef to find all resources
            String path = System.getProperty(JAVA_LIBRARY_PATH, "");
            if (!path.isEmpty() && !path.endsWith(File.pathSeparator)) {
                path += File.pathSeparator;
            }
            System.setProperty(JAVA_LIBRARY_PATH, path + installDir.getAbsolutePath());

            //Remove dependency loader from jcef (causes unnecessary errors due to wrong library names in jcef)
            SystemBootstrap.setLoader(libname -> {
                // no-op
            });

            try {
                // Load native libraries for jcef, as the jvm does not update the java library path
                System.loadLibrary("jawt");
            } catch (UnsatisfiedLinkError e) {
                LOGGER.warning("Error while loading jawt library: " + e.getMessage());
            }

            EnumPlatform platform = EnumPlatform.getCurrentPlatform();
            //Platform dependent loading code
            switch (platform.getOs()) {
                case WINDOWS -> {
                    System.load(new File(installDir, "chrome_elf.dll").getAbsolutePath());
                    System.load(new File(installDir, "libcef.dll").getAbsolutePath());
                    System.load(new File(installDir, "jcef.dll").getAbsolutePath());
                }
                case LINUX -> {
                    System.load(new File(installDir, "libjcef.so").getAbsolutePath());
                    boolean success = CefApp.startup(cefArgs.toArray(new String[0]));
                    if (!success) {
                        throw new CefInitializationException("JCef did not initialize correctly!");
                    }
                    System.load(new File(installDir, "libcef.so").getAbsolutePath());
                }
                case MACOSX -> {
                    System.load(new File(installDir, "libjcef.dylib").getAbsolutePath());
                    cefArgs.add(0, "--framework-dir-path=" + installDir.getAbsolutePath() + "/Chromium Embedded Framework.framework");
                    cefArgs.add(0, "--main-bundle-path=" + installDir.getAbsolutePath() + "/jcef Helper.app");
                    cefArgs.add(0, "--browser-subprocess-path=" + installDir.getAbsolutePath() + "/jcef Helper.app/Contents/MacOS/jcef Helper");
                    cefSettings.browser_subprocess_path = installDir.getAbsolutePath() + "/jcef Helper.app/Contents/MacOS/jcef Helper";
                    boolean success = CefApp.startup(cefArgs.toArray(new String[0]));
                    if (!success) {
                        throw new CefInitializationException("JCef did not initialize correctly!");
                    }
                }
                default -> throw new UnsupportedPlatformException(
                        System.getProperty(EnumPlatform.PROPERTY_OS_NAME),
                        System.getProperty(EnumPlatform.PROPERTY_OS_ARCH));
            }
            //Configure cef settings and create app instance (currently nothing to configure, may change in the future)
            return CefApp.getInstance(cefArgs.toArray(new String[0]), cefSettings);
        } catch (RuntimeException e) {
            throw new CefInitializationException("Error while initializing JCef", e);
        }
    }
}
