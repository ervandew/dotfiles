// compile: javac "<file>"
// execute: java -client -cp "<path>" regex "<file>" <flags>
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.StringWriter;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Command to evaluate the specified regex test file.
 *
 * @author Eric Van Dewoestine
 */
public class regex
{
  public static void main(String[] args)
    throws Exception
  {
    String file = args[0];
    String flags = args.length > 1 ? args[1] : "";
    evaluate(file, flags);
  }

  /**
   * Evaluates the supplied test regex file.
   *
   * @param file The file name.
   * @param flags The regex flags to be applied to the pattern.
   */
  private static void evaluate(String file, String flags)
    throws Exception
  {
    String regex = null;
    FileInputStream fis = null;
    try{
      fis = new FileInputStream(file);
      BufferedReader reader = new BufferedReader(new InputStreamReader(fis));
      reader.mark(1024); // should hopefully be plenty

      // read the pattern from the first line of the file.
      regex = reader.readLine();
      if (regex == null){
        return;
      }
      reader.reset();

      StringWriter out = new StringWriter();
      int n = 0;
      char[] buffer = new char[1024];
      while ((n = reader.read(buffer)) != -1) {
        out.write(buffer, 0, n);
      }

      String contents = out.toString();

      int pflags = 0;
      if (flags.indexOf('m') != -1){
        pflags |= Pattern.MULTILINE;
      }
      if (flags.indexOf('i') != -1){
        pflags |= Pattern.CASE_INSENSITIVE;
      }
      if (flags.indexOf('d') != -1){
        pflags |= Pattern.DOTALL;
      }

      Pattern pattern = Pattern.compile(regex.trim(), pflags);
      Matcher matcher = pattern.matcher(contents);

      // force matching to start past the first line.
      if(matcher.find(regex.length() + 1)){
        processFinding(matcher);
      }
      while(matcher.find()){
        processFinding(matcher);
      }
    }finally{
      try{
        fis.close();
      }catch(Exception e){
      }
    }
  }

  /**
   * Process the current regex finding.
   *
   * @param matcher The Matcher.
   */
  private static void processFinding(Matcher matcher)
  {
    StringBuffer result = new StringBuffer();

    result
      .append(matcher.start())
      .append('-')
      .append(matcher.end() - 1);

    for (int ii = 1; ii <= matcher.groupCount(); ii++){
      if (matcher.start(ii) >= 0){
        result
          .append(',')
          .append(matcher.start(ii))
          .append('-')
          .append(matcher.end(ii) - 1);
      }
    }
    System.out.println(result);
  }
}
