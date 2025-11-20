package me.tytoo.jcefmaven.impl.platform;

/**
 * Defined patterns for different platforms.
 * Used to detect the current platform from the system properties.
 *
 * @author Fritz Windisch
 */
public final class PlatformPatterns {
    private PlatformPatterns() {
        // utility class
    }

    public static final String[] OS_MACOSX = new String[]{"mac", "darwin"};
    public static final String[] OS_LINUX = new String[]{"nux"};
    public static final String[] OS_WINDOWS = new String[]{"win"};

    public static final String[] ARCH_AMD64 = new String[]{"amd64", "x86_64"};
    public static final String[] ARCH_I386 = new String[]{"x86", "i386", "i486", "i586", "i686", "i786"};
    public static final String[] ARCH_ARM64 = new String[]{"arm64", "aarch64"};
    public static final String[] ARCH_ARM = new String[]{"arm"};
}
