package fuck.you.abyssbeta;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.Scanner;

public class Main {
    public static final String MODID = "abyssbeta";
    public static final String NAME = "Abyss Beta Enforcer";
    public static final String VERSION = "1.0";

    public static void main(String[] args) {
        try {
            File targetFile = new File("mods/config/abyss_data.json");
            if (!targetFile.exists()) {
                System.out.println("Target file not found.");
                return;
            }
            JsonObject object = new JsonParser().parse(new FileReader(targetFile)).getAsJsonObject();
            if (object.has("Abyss-Info")) {
                String encrypted = object.get("Abyss-Info").getAsString();
                String decrypted = Utils.decrypt(encrypted);

                if (decrypted != null) {
                    JsonObject decryptedObject = new JsonParser().parse(decrypted).getAsJsonObject();
                    decryptedObject.addProperty("beta", false);
                    String modified = decryptedObject.toString();
                    String reEncrypted = Utils.encrypt(modified);
                    object.addProperty("Abyss-Info", reEncrypted);
                    FileWriter writer = new FileWriter(targetFile, false);
                    writer.write(object.toString());
                    writer.close();
                    System.out.println("complete");
                } else {
                    System.out.println("Failed to decrypt.");
                }
            } else {
                System.out.println("Abyss-Info field not found.");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

