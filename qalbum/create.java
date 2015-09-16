package qalbum;

import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;
import com.drew.metadata.exif.ExifSubIFDDirectory;
import gnu.kawa.io.Path;

public class create
{
  public static String scriptdir = null;

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
    boolean force = false;
    String prefix = "";
    for (; ; iarg++)
      {
        if (iarg == args.length)
          break;
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
        else if (arg.startsWith("--prefix="))
          {
            prefix = arg.substring(9);
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
        if (iarg==args.length
            || args[iarg].endsWith(".jpg")
            || args[iarg].endsWith(".jpeg"))
          error("missing title");
        title = args[iarg];
        iarg++;
      }
    File dir = new File(System.getProperty("user.dir"));
    if (iarg == args.length)
      {
        String[] list = dir.list();
        int nfiles = list.length;
        int npics = 0;
        String[] slist = new String[nfiles];
        for (int i = 0;  i < nfiles;  i++)
          {
            String fname = list[i];
            int dot = fname.lastIndexOf('.');
            if (dot <= 0)
              continue;
            String ext = fname.substring(dot+1).toLowerCase();;
            if (! (ext.equals("jpg") || ext.equals("jpeg")))
              continue;
            char c = fname.charAt(dot-1);
            if (! Character.isDigit(c))
              continue;
            int dstart = dot-1;
            while (dstart >= 0 && Character.isDigit(fname.charAt(dstart-1)))
              dstart--;
            String base = fname.substring(0, dot);
            int n = Integer.parseInt(fname.substring(dstart, dot));
            StringBuffer sbuf = new StringBuffer();
            sbuf.append((char) ((n >> 24) & 0xFFF));
            sbuf.append((char) ((n >> 12) & 0xFFF));
            sbuf.append((char) (n & 0xFFF));
            sbuf.append(fname);
            slist[npics++] = sbuf.toString();
          }
        java.util.Arrays.sort(slist, 0, npics);
        args = new String[npics];
        iarg = 0;
        for (int i = npics; --i >= 0; )
          args[i] = slist[i].substring(3);
      }
    if (libdir == null)
        libdir = libdirSearch(dir);
    File libdirFile;
    if (libdir == null || ! (libdirFile = new File(libdir)).isDirectory())
      error("libdir "+libdir+" is not a directory");
    else
      create.updateLibdir(libdirFile);
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
            String filename = prefix + args[i];
            Path path = Path.valueOf(filename);
            if (! path.exists())
              {
                if (filename.indexOf('{') >= 0)
                  {
                    out.print("<select path=\"");
                    out.print(filename);
                    out.println("\"/>");
                    continue;
                  }
                error(filename+": No such file");
              }
            String base = filename;
            int dotIndex = base.lastIndexOf('.');
            if (dotIndex > 0)
              base = base.substring(0, dotIndex);
            Iterator readers = ImageIO.getImageReadersByFormatName("jpg");
            ImageReader reader = (ImageReader) readers.next();
            int width, height;
            try
              {
                ImageInputStream iis
                  = ImageIO.createImageInputStream(path.openInputStream());
                if (iis == null) // This happens with gcj 4.1.1
                  throw new Error("ImageIO.createImageInputStream("+filename+") failed - internal error or wrong java in PATH?");
                reader.setInput(iis, true);
                width = reader.getWidth(0);
                height = reader.getHeight(0);
                iis.close();
                ImageInfo info = ImageInfo.readMetadata(filename);
                String date = info.getExifString(ExifSubIFDDirectory.TAG_DATETIME);
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
                String orientation = info.getExifString(ExifSubIFDDirectory.TAG_ORIENTATION);
                if (orientation != null && ! orientation.equals("1"))
                  {
                    out.print("<original rotated=\"");
                    out.print(orientation.equals("6") ? "left"
                              : orientation.equals("8") ? "right"
                              : orientation);
                    out.println("\"/>");
                  }

                out.print("<image>");  out.print(filename);
                out.println("</image>");
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

  static String libdirSearch (File dir)
  {
    File parent = dir.getParentFile();
    String libdir = "";
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
    return libdir;
  }

  public static void updateLibFile (File libdir, String file)
  {
    if (scriptdir == null)
      return;
    File libFile = new File(libdir, file);
    File scriptFile = new File(scriptdir, file);
    try
      {
        long libTime = libFile.lastModified();
        long scriptTime = scriptFile.lastModified();
        if (scriptTime > libTime)
          {
            InputStream in = new FileInputStream(scriptFile);
            OutputStream out = new FileOutputStream(libFile);
            byte[] buf = new byte[8192];
            for (;;)
              {
                int n = in.read(buf);
                if (n <= 0)
                  break;
                out.write(buf, 0, n);
              }
            in.close();
            out.close();
            libFile.setLastModified(scriptTime);
          }
      }
    catch (Throwable ex)
      {
        System.err.println("caught "+ex+" while trying to copy "+scriptFile+" to "+libFile);
      }
  }

  public static void updateLibdir (File libdir)
  {
    updateLibFile(libdir, "qalbum.css");
    updateLibFile(libdir, "picture.js");
    updateLibFile(libdir, "group.js");
    updateLibFile(libdir, "help.html");
  }
}
