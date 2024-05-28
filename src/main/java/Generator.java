import java.io.File;
import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;
import java.nio.file.Files;
import java.nio.file.Paths;
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

    public void saveJsonToToFile(ObjectNode json, String filePath) {
      synchronized (json) {
          try {
              mapper.writerWithDefaultPrettyPrinter().writeValue(new File(filePath), json);
          } catch (IOException e) {
            System.out.println(e);
            System.out.println("FAILED TO SAVE GENERATOR RESULTS");
          }
      }
    }

    private void initialiseGeneratorResults(String filePath) {
      File f = new File(filePath);
      if (f.exists()) {
        try {
          generatorResults = (ObjectNode) mapper.readTree(f);
        } catch (IOException e) {
          System.out.println("FAILED TO INITIALISED GENERATOR RESULTS");
          e.printStackTrace();
        }
        return;
      }

      try {
        f.getParentFile().mkdirs();
        f.createNewFile();
      } catch (IOException e) {
        System.out.println("FAILED TO INITIALISED GENERATOR RESULTS");
        e.printStackTrace();
      }
      StringBuilder sb = new StringBuilder();
      sb.append(
        "{\"" + config + "\":" 
                            + "{\"averageGenerationTimeMs\": 0,"
                            + "\"filesGenerated\": 0,"
                            + "\"averageLineCount\": 0,"
                            + "\"numberOfGeneratorCrashes\": 0," 
                            + "\"numberOfTimeouts\": 0}}");
      try {
        generatorResults = (ObjectNode) mapper.readTree(sb.toString());
      } catch (IOException e) {
        System.out.println("FAILED TO INITIALISED GENERATOR RESULTS");
      }
      saveJsonToToFile(generatorResults, filePath);
    }

    private int getFileCount(String filePath) {
      try {
          int lineCount = (int) Files.lines(Paths.get(filePath)).count();
          return lineCount;
      } catch (IOException e) {
          System.out.println("ERROR CALCULATING PROGRAM LINE COUNT");
          System.out.println(e);
          return -1;
      }
    }

    @Override
    public void run() {
      String generatorResultsFilePath = "./output/" + "thread" + id + "/" + "generatorResults.json";

      initialiseGeneratorResults(generatorResultsFilePath);

      for (int i = 1; i < numPrograms + 1; i++) {
        ObjectNode configJson = (ObjectNode) generatorResults.get(config);
        int currentFilesGenerated = (configJson.get("filesGenerated")).asInt();

        String progLocation = "output/" + "thread" + id + "/" + config + "/prog" + (currentFilesGenerated + 1) + ".kt";
        String generatorConfigDir = GENERATORS_DIR + config;
        ProcessBuilder pb = new ProcessBuilder("./generate.sh", generatorConfigDir, "../" + progLocation);
        pb.directory(new File("./scripts"));

        saveJsonToToFile(generatorResults, generatorResultsFilePath);
        


        while (true) {
          try {
            long wallStartTime = System.nanoTime();
            Process p = pb.start();
            int exitCode = p.waitFor();
            long wallEndTime = System.nanoTime();
  
            if (exitCode == 124) {
              System.out.println("(THREAD " + id + ") TIMEOUT (Trying again)");
              configJson.put("numberOfTimeouts", 
                configJson.get("numberOfTimeouts").asInt() + 1);
            } else if (exitCode == 0) {
              long wallDuration = (wallEndTime - wallStartTime) / 1000000; 
              System.out.println("(THREAD " + id + ") Generated program " + i + "/" + numPrograms);
              configJson.put("filesGenerated", currentFilesGenerated + 1);
              long avgWallDuration = (configJson.get("averageGenerationTimeMs").asLong() * (currentFilesGenerated) + wallDuration) / (currentFilesGenerated + 1);
              configJson.put("averageGenerationTimeMs", avgWallDuration);
              int currentAvgLineCount = (configJson.get("averageLineCount")).asInt();
              int lineCount = getFileCount(progLocation);
              lineCount = lineCount == - 1 ? currentAvgLineCount : lineCount;
              int newAvgLineCount = (currentAvgLineCount * (currentFilesGenerated) + lineCount) / (currentFilesGenerated + 1);
              configJson.put("averageLineCount", newAvgLineCount);
              break;
            } else {
              System.out.println("(THREAD " + id + ") GENERATOR CRASH (Trying again)");
              configJson.put("numberOfGeneratorCrashes", 
                configJson.get("numberOfGeneratorCrashes").asInt() + 1);
            }
          } catch (Exception e) {
            System.err.println(e);
          }
        }
        saveJsonToToFile(generatorResults, generatorResultsFilePath);
      }
      
    }
    
  }
}