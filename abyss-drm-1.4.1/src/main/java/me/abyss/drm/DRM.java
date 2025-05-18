package me.abyss.drm;

import net.minecraftforge.fml.relauncher.IFMLLoadingPlugin;
import net.minecraft.launchwrapper.Launch;
import net.minecraft.launchwrapper.LaunchClassLoader;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.tools.JavaCompiler;
import javax.tools.ToolProvider;
import javax.annotation.Nullable;
import java.io.*;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.*;
import java.security.Key;
import java.util.*;
import java.util.jar.*;

@SuppressWarnings("deprecation")
@IFMLLoadingPlugin.Name("DRM")
@IFMLLoadingPlugin.SortingIndex(1001)
public class DRM implements IFMLLoadingPlugin {

    private static final String PASSWORD = "1234567890123456"; // AES-128
    private static final byte[] IV = "abcdefghijklmnop".getBytes();  // 16-byte IV

    static {
        try {
            File modsDir = new File("mods");
            File tempDir = new File("decrypted_mods");
            tempDir.mkdirs();

            for (File jar : Objects.requireNonNull(modsDir.listFiles((dir, name) -> name.endsWith(".jar")))) {
                processEncryptedJavaFilesInJar(jar, tempDir);
            }

            compileAndInject(tempDir);

        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("[DRM] Critical failure.");
        }
    }

    private static void processEncryptedJavaFilesInJar(File jarFile, File outputDir) throws Exception {
        try (JarFile jar = new JarFile(jarFile)) {
            Enumeration<JarEntry> entries = jar.entries();
            while (entries.hasMoreElements()) {
                JarEntry entry = entries.nextElement();
                if (!entry.isDirectory() && entry.getName().endsWith(".java")) {
                    InputStream is = jar.getInputStream(entry);
                    File outFile = new File(outputDir, new File(entry.getName()).getName());
                    decryptStreamToFile(is, outFile);
                    System.out.println("[DRM] Decrypted source: " + entry.getName());
                }
            }
        }
    }

    private static void decryptStreamToFile(InputStream inputStream, File outputFile) throws Exception {
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        Key secretKey = new SecretKeySpec(PASSWORD.getBytes(), "AES");
        cipher.init(Cipher.DECRYPT_MODE, secretKey, new IvParameterSpec(IV));

        try (CipherInputStream cis = new CipherInputStream(inputStream, cipher);
             FileOutputStream fos = new FileOutputStream(outputFile)) {

            byte[] buffer = new byte[4096];
            int read;
            while ((read = cis.read(buffer)) != -1) {
                fos.write(buffer, 0, read);
            }
        }
    }

    private static void compileAndInject(File javaSourceDir) throws IOException {
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();

        File classOutputDir = new File("compiled_mods");
        classOutputDir.mkdirs();

        List<File> javaFiles = new ArrayList<>();
        collectJavaFiles(javaSourceDir, javaFiles);

        List<String> filePaths = new ArrayList<>();
        for (File file : javaFiles) filePaths.add(file.getPath());

        int result = compiler.run(null, null, null, "-d", classOutputDir.getPath(), String.join(" ", filePaths));
        if (result != 0) {
            System.err.println("[DRM] Compilation failed.");
            return;
        }

        try {
            injectCompiledClasses(classOutputDir);
        } catch (Exception e) {
            e.getSuppressed();
        }
    }

    private static void collectJavaFiles(File dir, List<File> javaFiles) {
        for (File file : Objects.requireNonNull(dir.listFiles())) {
            if (file.isDirectory()) {
                collectJavaFiles(file, javaFiles);
            } else if (file.getName().endsWith(".java")) {
                javaFiles.add(file);
            }
        }
    }

    private static void injectCompiledClasses(File classDir) throws Exception {
        URL url = classDir.toURI().toURL();
        LaunchClassLoader loader = Launch.classLoader;
        loader.addURL(url);
        System.out.println("[DRM] Injected compiled classes from: " + classDir.getName());
    }

    @Override
    public String[] getASMTransformerClass() {
        return new String[0];
    }

    @Override
    public String getModContainerClass() {
        return null;
    }

    @Override
    @Nullable
    public String getSetupClass() {
        return null;
    }

    @Override
    public void injectData(Map<String, Object> data) {}

    @Override
    public String getAccessTransformerClass() {
        return null;
    }
}
