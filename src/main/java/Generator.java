import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

public class Generator {
  public static final String GENERATORS_DIR = "../generators/";
  public static final int NUM_OF_THREADS = 4;
  

  public static void main(String[] args) {

    String config = args[0];
    int numPrograms = Integer.parseInt(args[1]);

    ExecutorService executor = Executors.newFixedThreadPool(NUM_OF_THREADS);
    for (int i = 1; i < NUM_OF_THREADS + 1; i++){
      Runnable task = new GenerateTask(i, config, numPrograms / 4);
      executor.submit(task);
    }
    
    executor.shutdown();

    try {
      executor.awaitTermination(72, TimeUnit.HOURS);
    } catch (InterruptedException e) {
      System.out.println("======= GENERATION FAILED ======");
      e.printStackTrace();
    }
  }

  private static class GenerateTask implements Runnable {
    private final int id;
    private final String config;
    private final int numPrograms;
    private final ObjectMapper mapper = new ObjectMapper();
    private ObjectNode generatorResults;

    public GenerateTask(int id, String config, int numPrograms) {
      this.id = id;
      this.config = config;
      this.numPrograms = numPrograms;
    }

    public void saveJsonToToFile(ObjectNode json, String filename) {
      synchronized (json) {
          try {
              mapper.writerWithDefaultPrettyPrinter().writeValue(new File(filename), json);
          } catch (IOException e) {
            System.out.println(e);
            System.out.println("FAILED TO SAVE GENERATOR RESULTS");
          }
      }
    }

    private void initialiseGeneratorResults() {
      StringBuilder sb = new StringBuilder();
      sb.append(
        "{\"" + config + "\":" 
                            + "{\"averageGenerationTime\": 0,"
                            + "\"numberOfGeneratorCrashes\": 0," 
                            + "\"numberOfTimeouts\": 0}}");
      try {
        generatorResults = (ObjectNode) mapper.readTree(sb.toString());
      } catch (IOException e) {
        System.out.println("FAILED TO INITIALISED GENERATOR RESULTS");
      }
    }

    @Override
    public void run() {

      initialiseGeneratorResults();

      for (int i = 1; i < numPrograms + 1; i++) {
        String progLocation = "../output/" + "thread" + id + "/" + config + "/prog" + i + ".kt";
        String generatorConfigDir = GENERATORS_DIR + config;
        ProcessBuilder pb = new ProcessBuilder("./generate.sh", generatorConfigDir, progLocation);
        pb.directory(new File("./scripts"));

        saveJsonToToFile(generatorResults, "./output/" + "thread" + id + "/" + "generatorResults.json");

        while (true) {
          try {
            long startTime = System.nanoTime();
            Process p = pb.start();
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
              long avgDuration = (configJson.get("averageGenerationTime").asLong() * (i - 1) + duration) / i;
              configJson.put("averageGenerationTime", avgDuration);
              break;
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
        saveJsonToToFile(generatorResults, "./output/" + "thread" + id + "/" + "generatorResults.json");
      }
      
    }
    
  }
}