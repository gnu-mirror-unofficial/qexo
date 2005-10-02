package qalbum;

import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;

public class create
{
  static void error (String msg)
  {
    System.err.println(msg);
    System.exit(-1);
  }

  public static void main (String[] args)
  {
    if (args.length <= 1)
      {
	System.err.println("Usage: \"album title\" file1.jpg file2.jpg ...");
	System.exit(-1);
      }
    String title = args[0];
    File indexFile = new File("index.xml");
    if (indexFile.exists())
      {
	System.err.println("The file index.xml already exists.");
	System.err.println("Delete it first if you're sure you don't want it.");
	System.exit(-1);
      }
    // We build the output in an initial StringWriter, so we don't
    // create a partial index.xml if there is an exception.
    StringWriter sout = new StringWriter(8000);
    PrintWriter out = new PrintWriter(sout);
    try
      {
        out.println("<?xml version=\"1.0\"?>");
        out.println("<group>");
        out.println("<title>" + title + "</title>");

        int iend = args.length;
        for (int i = 1;  i < iend;  i++)
          {
            String filename = args[i];
            File file =  new File(filename);
            if (! file.exists())
              error(filename+": No such file");
            String base = file.getName();
            int dotIndex = base.lastIndexOf('.');
            if (dotIndex > 0)
              base = base.substring(0, dotIndex);
            Iterator readers = ImageIO.getImageReadersByFormatName("jpg");
            ImageReader reader = (ImageReader) readers.next();
            int width, height;
            try
              {
                ImageInputStream iis = ImageIO.createImageInputStream(file);
                reader.setInput(iis, true);
                width = reader.getWidth(0);
                height = reader.getHeight(0);
                iis.close();
                out.print("<picture id=\"");  out.print(base);
                out.println("\">");
                String tag = width <= 700 || height <= 700 ? "image" : "full-image";
                //System.err.println("file: "+filename+" width: "+width+" height: "+height+" tag:"+tag);
                out.print('<');  out.print(tag);
                out.print(" width=\"");  out.print(width);
                out.print("\" height=\"");  out.print(height);
                out.print("\">");  out.print(filename);
                out.print("</");  out.print(tag);  out.println('>');
                out.println("</picture>");
              }
            catch (Throwable ex)
              {
                error(filename+": caught "+ex.getMessage());
              }
          }
        out.println("</group>");
        out.flush();
        FileWriter fout = new FileWriter(indexFile);
        fout.write(sout.toString());
        fout.close();
      }
    catch (Throwable ex)
      {
	error("Caught exception: "+ex+" msg:"+ex.getMessage());
      }
  }
}
