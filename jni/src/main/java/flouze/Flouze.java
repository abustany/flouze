package flouze;

class Flouze {
    private static boolean initialized = false;

    public static synchronized void init() {
        if (!initialized) {
            System.loadLibrary("flouze_jni");
            initialized = true;
        }
    }
}
