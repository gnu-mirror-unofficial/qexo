package qalbum;

import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;
import com.drew.metadata.exif.ExifDirectory;

public class create
{
  static void error (String msg)
  {
    System.err.println(msg);
    System.exit(-1);
  }

  public static void main (String[] args)
  {
    int iarg = 0;
    String title = null;
    String libdir = null;
    String scriptdir = null;
    boolean force = false;
    for (; ; iarg++)
      {
        if (iarg == args.length)
          {
            error("Usage: \"album title\" file1.jpg file2.jpg ...");
          }
        String arg = args[iarg];
        if (! arg.startsWith("-"))
          break;
        if (arg.startsWith("--libdir="))
          {
            libdir = arg.substring(9);
          }
        else if (arg.startsWith("--scriptdir="))
          {
            scriptdir = arg.substring(12);
          }
        else if (arg.startsWith("--title="))
          {
            title = arg.substring(8);
          }
        else if (arg.equals("--force"))
          {
            force = true;
          }
        else
          {
            error("unrecognized option: "+arg);
          }
      }
    File indexFile = new File("index.xml");
    if (indexFile.exists() && ! force)
      {
	System.err.println("The file index.xml already exists.");
	System.err.println("Delete it first if you're sure you don't want it.");
	System.exit(-1);
      }
    if (title == null)
      {
        if (iarg+1==args.length
            || args[iarg].endsWith(".jpg")
            || args[iarg].endsWith(".jpeg"))
          error("missing title");
        title = args[iarg];
        iarg++;
      }
    if (libdir == null)
      {
        File dir = new File(System.getProperty("user.dir"));
        File parent = dir.getParentFile();
        libdir = "";
        for (;;)
          {
            if (parent == null)
              error("cannot find an existing ..../lib for libdir");
            String dpath = dir.getPath();
            File ldir = new File(dir, "lib");
            if (ldir.isDirectory())
              {
                libdir = libdir+"lib";
                break;
              }
            dir = parent;
            parent = dir.getParentFile();
            libdir = "../"+libdir;
          }
      }
    else if (! new File(libdir).isDirectory())
      {
        error("libdir "+libdir+" is not a directory");
      }
    // We build the output in an initial StringWriter, so we don't
    // create a partial index.xml if there is an exception.
    StringWriter sout = new StringWriter(8000);
    PrintWriter out = new PrintWriter(sout);
    try
      {
        out.println("<?xml version=\"1.0\"?>");
        out.println("<group libdir=\""+libdir+"\">");
        out.println("<title>" + title + "</title>");

        int iend = args.length;
        String prevDate = null;
        for (int i = iarg;  i < iend;  i++)
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
                ImageInfo info = ImageInfo.readMetadata(file, filename);
                String date = info.getExifString(ExifDirectory.TAG_DATETIME);
                if (date != null && date.length() >= 10)
                  {
                    date = date.substring(0, 10).replace(':', '/');
                    if (! date.equals(prevDate))
                      {
                        out.print("<date>");
                        out.print(date);
                        out.println("</date>");
                        prevDate = date;
                      }
                  }
                out.print("<picture id=\"");  out.print(base);
                out.println("\">");
                String orientation = info.getExifString(ExifDirectory.TAG_ORIENTATION);
                if (orientation != null && ! orientation.equals("1"))
                  {
                    out.print("<original rotated=\"");
                    out.print(orientation.equals("6") ? "left"
                              : orientation.equals("8") ? "right"
                              : orientation);
                    out.println("\"/>");
                  }

                String tag = width <= 700 || height <= 700 ? "image" : "full-image";
                out.print('<');  out.print(tag);
                out.print('>');  out.print(filename);
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
