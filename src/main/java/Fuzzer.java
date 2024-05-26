import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;


public class Fuzzer {
    public static final int NUMBER_OF_PROGRAMS_PER_CONGIFG = 1;
    public static final String GENERATORS_DIR = "../generators/";
    public static final String[] CONFIGS = new String[]{"config1"};

    public static void main(String[] args) {

      System.out.println("======== Starting concurrent fuzz ==========");
      for (String config : CONFIGS) {
        System.out.println("Using " + config);
        for (int i = 1; i < NUMBER_OF_PROGRAMS_PER_CONGIFG + 1; i++) {
          generateProgram(config, i);

          System.out.println("Generated program " + i + "/" + 
          NUMBER_OF_PROGRAMS_PER_CONGIFG + " using " + config);
          
          //check for bugs
        }
      }
    }

    private static void generateProgram(String config, int programIndex) {
      String progLocation = "../output/" + config + "/all/" + "prog" + programIndex + ".kt";
      String generatorConfigDir = GENERATORS_DIR + config;
      ProcessBuilder pb = new ProcessBuilder("./generate.sh", generatorConfigDir, progLocation);
      pb.directory(new File("./scripts"));
      while (true) {
        try {
          Process p = pb.start();
          StringBuilder output = new StringBuilder();
          try (BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append(System.lineSeparator());
            }
          }
          System.out.println(output.toString());
          int exitCode = p.waitFor();


          if (exitCode == 124) {
            System.out.println("TIMEOUT (Trying again)");
          } else if (exitCode == 0) {
            return;
          } else {
            System.out.println("GENERATOR CRASH (Trying again)");
          }
        } catch (Exception e) {
          System.err.println(e);
        }
      }
    }
}