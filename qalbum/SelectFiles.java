package qalbum;
import gnu.mapping.*;
import gnu.kawa.io.Path;
import java.io.*;
import java.util.*;
import java.util.regex.*;

public class SelectFiles
{
  public static void selectFiles$X (String pattern, CallContext ctx)
    throws Throwable
  {
    selectFiles$X(pattern, null, ctx);
  }

  public static void selectFiles$X (String pattern, Object key, CallContext ctx)
    throws Throwable
  {
    int sl = pattern.lastIndexOf('/');
    String dirName;
    if (sl < 0)
      dirName = ".";
    else
      {
        dirName = pattern.substring(0, sl);
        pattern = pattern.substring(sl+1);
      }

    File dir = new File(dirName);
    String[] files = dir.list(new SelectFilter(pattern));
    Arrays.sort(files);
    boolean makeLinks = ! dirName.equals(".");

    for (int i = 0;  i < files.length; i++)
      {
        String origName = dir+"/"+files[i];
        ImageInfo image = ImageInfo.readMetadata(origName);
        if (! image.dontSkip())
          continue;
        if (makeLinks)
          {
            Path localPath = Path.valueOf(files[i]);
            if (! localPath.exists())
              {
                String[] linkArgs = {"/bin/sh", "-c",
                                     "ln -s "+origName+" "+files[i] };
                Process process = Runtime.getRuntime().exec(linkArgs);
                int exitCode = process.waitFor();
                if (exitCode != 0)
                  System.err.println("Unexpected ln exitCode:"+exitCode);
              }
            image.filename = localPath;
          }
        String label = files[i];
        int dot = label.lastIndexOf('.');
        if (dot > 0)
          label = label.substring(0,dot);
        PictureInfo pinfo = PictureInfo.getImages(label, "", image);
        pinfo.key = key;
        ctx.consumer.writeObject(pinfo);
      }
  }

  /*
  public accept(File pathname)
  {
    
  }
  */

  public static void main (String[] args) throws Throwable
  {
  }
}

class SelectFilter implements FilenameFilter
{
  String nameHead, nameTail;
  int headLength, tailLength;
  int loIndex, hiIndex;

  public SelectFilter (String pattern)
  {
    loIndex = -1;
    hiIndex = -1;

    Pattern rangePat = Pattern.compile("^(.*)\\{([0-9]*)\\.\\.*([0-9]*)\\}(.*)$");
    Pattern starPat = Pattern.compile("^(.*)\\*(.*)$");
    Matcher matcher =  rangePat.matcher(pattern);
    if (matcher.find())
      {
        nameHead = matcher.group(1);
        nameTail = matcher.group(4);
        String num1 = matcher.group(2);
        String num2 = matcher.group(3);
        if (num1.length() > 0)
          loIndex = Integer.parseInt(num1);
        else
          loIndex = 0;
        if (num2.length() > 0)
          hiIndex = Integer.parseInt(num2);
      }
    else if ((matcher = starPat.matcher(pattern)).find())
      {
        nameHead = matcher.group(1);
        nameTail = matcher.group(2);
      }
    else
      {
        nameHead = pattern;
        nameTail = "";
      }

    headLength = nameHead.length();
    tailLength = nameTail.length();
  }

  public boolean accept(File dir, String name)
  {
    int nameLength = name.length();
    if (headLength + tailLength > nameLength)
      return false;
    if (! nameHead.equals(name.substring(0, headLength))
        || ! nameTail.equals(name.substring(nameLength-tailLength)))
      return false;
    if (loIndex < 0 && hiIndex < 0)
      return true;
    String numStr = name.substring(headLength, nameLength-tailLength);
    try
      {
        int num = Integer.parseInt(numStr);
        return num >= loIndex && (hiIndex < 0 || num <= hiIndex); 
      }
    catch (NumberFormatException ex)
      {
        return false;
      }
  }
}
