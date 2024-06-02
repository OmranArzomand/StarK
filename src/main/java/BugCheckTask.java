import java.io.*;
import java.util.*;
import java.util.concurrent.*;

public class BugCheckTask implements Runnable {
  public final String progName;
  public final String progPath;

  public BugCheckTask(String progName) {
    this.progName = progName;
    this.progPath = ConcurrentFuzzer.TEMP_DIR + progName;
  }

  @Override
  public void run() {
    List<Integer> exitCodes;
    try {
      exitCodes = compileProgram();
    } catch (Exception e) {
      System.out.println("UNEXPECTED ERROR when trying to compile " + progName + "(ignoring bug checking)");
      cleanUp();
      return;
    }

    assert(exitCodes.size() == ConcurrentFuzzer.COMPILERS.length);
    if (!exitCodes.stream().allMatch(item -> item == 0)) {
      handleBug("compilers failed to compile", progName, exitCodes.stream().allMatch(item -> item == exitCodes.get(0)) ? ConcurrentFuzzer.COMPILER_ERROR_BUG_DIR : ConcurrentFuzzer.COMPILER_ERROR_MISMATCH_BUG_DIR);
      return;
    }
    List<String> runResults;
    try {
      runResults = runProgram();
    } catch (Exception e) {
      System.out.println("UNEXPECTED ERROR when trying to run " + progName + "(ignoring bug checking)");
      System.out.println(e);
      cleanUp();
      return;
    }

    assert(runResults.size() == ConcurrentFuzzer.COMPILERS.length);
    if (!runResults.stream().allMatch(item -> item.equals(runResults.get(0)))) {
      handleBug("Miscompilation found when running", progName, ConcurrentFuzzer.COMPILER_MISCOMPILATION_BUG_DIR);
    }
    cleanUp();
  }

  private void handleBug(String bugMessage, String progName, String bugDir) {
    System.out.println("BUG FOUND: " + bugMessage + " " + progName);
    File destination = new File(bugDir + progName);
    try {
      destination.createNewFile();
    } catch (IOException e) {
      System.out.println("Failed to create bug file: " + e.getMessage());
    }
    new File(progPath).renameTo(destination);
    cleanUp();
  }

  private List<String> runProgram() throws Exception {
    List<String> results = new ArrayList<>();
    for (String compiler : ConcurrentFuzzer.COMPILERS) {
      ProcessBuilder pb = new ProcessBuilder("./runCompiledJar.sh", "../" + ConcurrentFuzzer.TEMP_DIR + jarName(progName, compiler));
      pb.directory(new File("./scripts"));
      Process p = pb.start();
      String output = readProcessOutput(p);
      int exitCode = p.waitFor();
      if (exitCode == 124) {
        throw new RuntimeException("Running " + progName + " timed out");
      }
      results.add(output);
    }
    return results;
  }

  private List<Integer> compileProgram() throws Exception {
    List<Integer> exitCodes = new ArrayList<>();
    for (String compiler : ConcurrentFuzzer.COMPILERS) {
      ProcessBuilder pb = new ProcessBuilder("./compileProgram.sh",
        "../" + ConcurrentFuzzer.COMPILERS_DIR + compiler,
        "../" + progPath,
        "../" + ConcurrentFuzzer.TEMP_DIR + jarName(progName, compiler));
      pb.directory(new File("./scripts"));
      Process p = pb.start();
      readProcessOutput(p); // Read output to avoid blocking
      int exitCode = p.waitFor();
      if (exitCode == 124) {
        throw new RuntimeException("Compiling " + progName + " timed out");
      }
      exitCodes.add(exitCode);
    }
    return exitCodes;
  }

  private String readProcessOutput(Process p) throws IOException {
    try (BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));
         BufferedReader stdError = new BufferedReader(new InputStreamReader(p.getErrorStream()))) {
      StringBuilder output = new StringBuilder();
      String s;
      while ((s = stdInput.readLine()) != null) {
        output.append(s).append("\n");
      }
      while ((s = stdError.readLine()) != null) {
        output.append(s).append("\n");
      }
      return output.toString();
    }
  }

  private void cleanUp() {
    new File(progPath).delete();
    for (String compiler : ConcurrentFuzzer.COMPILERS) {
      String jarPath = ConcurrentFuzzer.TEMP_DIR + jarName(progName, compiler);
      new File(jarPath).delete();
    }
  }

  private String jarName(String progName, String compiler) {
    return progName.split(".kt")[0] + compiler + ".jar";
  }
}