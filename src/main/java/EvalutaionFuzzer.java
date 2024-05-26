import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

public class EvalutaionFuzzer {
    public static final int NUMBER_OF_PROGRAMS_PER_CONGIFG = 1;
    public static final String GENERATORS_DIR = "../generators/";
    public static final String[] CONFIGS = new String[]{"config1"};
    private static final ObjectMapper mapper = new ObjectMapper();
    private static ObjectNode generatorResults;
    private static final String GENERATOR_RESULTS_LOCATION = "./output/generatorResults.json";

    public static void main(String[] args) {

        initialiseGeneratorResults();

        System.out.println("======== Starting concurrent fuzz ==========");
        for (String config : CONFIGS) {
          System.out.println("Using " + config);
          for (int i = 1; i < NUMBER_OF_PROGRAMS_PER_CONGIFG + 1; i++) {
            generateProgram(config, i);

            System.out.println("Generated program " + i + "/" + 
            NUMBER_OF_PROGRAMS_PER_CONGIFG + " using " + config);

            // check for bugs
          }
        }

        saveJsonToToFile(generatorResults, GENERATOR_RESULTS_LOCATION);
    }

    private static void initialiseGeneratorResults() {
      StringBuilder sb = new StringBuilder();
      for (String config : CONFIGS) {
        sb.append(
          "{\"" + config + "\":" 
                             + "{\"averageGenerationTime\": 0,"
                              + "\"numberOfGeneratorCrashes\": 0," 
                              + "\"numberOfTimeouts\": 0}}");
      }
      
      try {
        generatorResults = (ObjectNode) mapper.readTree(sb.toString());
      } catch (IOException e) {
        System.out.println("FAILED TO INITIALISED GENERATOR RESULTS");
      }
    }

    public static void saveJsonToToFile(ObjectNode json, String filename) {
      synchronized (json) {
          try {
              mapper.writerWithDefaultPrettyPrinter().writeValue(new File(filename), json);
          } catch (IOException e) {
            System.out.println("FAILED TO SAVE GENERATOR RESULTS");
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
          long startTime = System.nanoTime();
          Process p = pb.start();
          StringBuilder output = new StringBuilder();
          try (BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append(System.lineSeparator());
            }
          }
          
          int exitCode = p.waitFor();
          long endTime = System.nanoTime();

          if (exitCode == 124) {
            System.out.println("TIMEOUT (Trying again)");
            ObjectNode configJson = (ObjectNode) generatorResults.get(config);
            configJson.put("numberOfTimeouts", 
              configJson.get("numberOfTimeouts").asInt() + 1);
          } else if (exitCode == 0) {
            long duration = (endTime - startTime) / 1000000;
            System.out.println("Took " + duration + "ms");
            ObjectNode configJson = (ObjectNode) generatorResults.get(config);
            long avgDuration = (configJson.get("averageGenerationTime").asLong() * (programIndex - 1) + duration) / programIndex;
            configJson.put("averageGenerationTime", avgDuration);
            return;
          } else {
            System.out.println("GENERATOR CRASH (Trying again)");
            ObjectNode configJson = (ObjectNode) generatorResults.get(config);
            configJson.put("numberOfGeneratorCrashes", 
              configJson.get("numberOfGeneratorCrashes").asInt() + 1);
          }
        } catch (Exception e) {
          System.err.println(e);
        }
      }
    }
}