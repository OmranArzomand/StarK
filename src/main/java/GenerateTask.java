import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.concurrent.Callable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class GenerateTask implements Callable<GeneratorResult> {
  private final String config;
  private final String progName;
  private final String outDir;

  public GenerateTask(String config, String outDir, String progName) {
    this.config = config;
    this.progName = progName;
    this.outDir = outDir;
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

  private double getWallTimeFromOutput(String output) {
    Pattern pattern = Pattern.compile("real\\s+(\\d+)m([\\d\\.]+)s");
    Matcher matcher = pattern.matcher(output);

    if (matcher.find()) {
      int minutes = Integer.parseInt(matcher.group(1));
      double seconds = Double.parseDouble(matcher.group(2));        
      return  Integer.parseInt(matcher.group(1)) * 60 + Double.parseDouble(matcher.group(2));
    } else {
      System.out.println("ERROR GETTING WALL TIME FROM GENERATION SCRIPT OUTPUT");
      return -1;
    }
  }

  private double getCpuTimeFromOutput(String output) {
    Pattern pattern = Pattern.compile("user\\s+(\\d+)m([\\d\\.]+)s");
    Matcher matcher = pattern.matcher(output);

    if (matcher.find()) {
      int minutes = Integer.parseInt(matcher.group(1));
      double seconds = Double.parseDouble(matcher.group(2));        
      return  Integer.parseInt(matcher.group(1)) * 60 + Double.parseDouble(matcher.group(2));
    } else {
      System.out.println("ERROR GETTING WALL TIME FROM GENERATION SCRIPT OUTPUT");
      return -1;
    }
  }

  @Override
  public GeneratorResult call() {
    String progLocation = outDir + progName;
    String generatorConfigDir = "../" + Generator.GENERATORS_DIR + config;
    ProcessBuilder pb = new ProcessBuilder("./generate.sh", generatorConfigDir, "../" + progLocation);
    //ProcessBuilder pb = new ProcessBuilder("./generateBBF.sh", generatorConfigDir, "../" + progLocation);
    pb.directory(new File("./scripts"));

    double wallGenerationTime;
    double cpuGenerationTime;
    int numCrashes = 0;
    int numTimeouts = 0;
    int lineCount;
    
    while (true) {
      try {
        Process p = pb.start();
        String output = new String(p.getErrorStream().readAllBytes());
        int exitCode = p.waitFor();

        if (exitCode == 124) {
          System.out.println("Generating " + progName + " TIMED OUT (Trying again)");
          numTimeouts++;
        } else if (exitCode == 0) {
          wallGenerationTime = getWallTimeFromOutput(output);
          cpuGenerationTime = getCpuTimeFromOutput(output);
          System.out.println("Generated " + progName);
          lineCount = getFileCount(progLocation);
          break;
        } else {
          System.out.println("Generating " + progName + " CRASHED (Trying again)");
          numCrashes++;
        }
      } catch (Exception e) {
        System.err.println(e);
      }
    }
    return new GeneratorResult(numTimeouts, wallGenerationTime, cpuGenerationTime, lineCount, numCrashes); 
  }
}