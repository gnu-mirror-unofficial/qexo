package qalbum;
import java.io.*;
import gnu.text.*;
import gnu.mapping.*;

public class qalbum
{
  static File userdir = new File(System.getProperty("user.dir"));

  public static void main (String[] args)
  {
    process(userdir, args);
  }
  public static void process (File dir, String[] args)
  {
    int iarg = 0;
    for (;; iarg++)
      {
        if (iarg == args.length)
          {
            generate(dir, new String[0]);
            break;
          }
        String arg = args[iarg];
        if (arg.equals("generate"))
          {
            String[] xargs = new String[args.length-iarg-1];
            if (xargs.length > 0)
              System.arraycopy(args, iarg+1, xargs, 0, xargs.length);
            generate(dir, xargs);
          }
        else if (arg.equals("-R") || arg.equals("--recursive"))
          {
            String[] xargs = new String[args.length-iarg-1];
            if (xargs.length > 0)
              System.arraycopy(args, iarg+1, xargs, 0, xargs.length);
            recursive(dir, xargs);
          }
        else if (arg.equals("create") || arg.equals("new")
                 || arg.equals("--create") || arg.equals("--new"))
          {
            String[] xargs = new String[args.length-iarg-1];
            if (xargs.length > 0)
              System.arraycopy(args, iarg+1, xargs, 0, xargs.length);
            create.main(xargs);
            if (arg.equals("new") || arg.equals("--new"))
              generate(dir, new String[0]);
          }
        else if (arg.equals("version") || args.equals("--version"))
          {
            System.out.println("qalbum Coperyright 2007 Per Bothner");
          }
        else if (arg.startsWith("--scriptdir="))
          {
            create.scriptdir = arg.substring(12);
            continue;
          }
        else
          help();
        break;
      }
  }

  public static void recursive (File dir, String[] args)
  {
    File[] list = dir.listFiles();
    File indexFile = new File(dir, "index.xml");
    if (indexFile.exists())
      {
        System.out.println("Processing "+indexFile);
        CallContext.getInstance().setBaseUri(dir.toURI().toString());
        if (args.length == 0) // Optimization.
          generate(indexFile, dir, args);
        else
          process(dir, args);
      }
    int nfiles = list.length;
    for (int i = 0;  i < nfiles;  i++)
      {
        if (list[i].isDirectory())
          recursive(list[i], args);
      }
  }

  public static void generate (File dir, String[] args)
  {
    File indexFile = new File(dir, "index.xml");
    if (! indexFile.exists())
      help();
    else
      generate(indexFile, dir, args);
  }

  public static void generate (File indexFile, File dir, String[] args)
  {
    String libdir = null;
    try
      {
        InputStream ins = URI_utils.getInputStream(indexFile);
        InPort inp = new InPort(ins);
        for (;;)
          {
            String line = inp.readLine();
            if (line == null)
              break;
            String pat = "<group libdir=";
            int patlen = pat.length();
            int pos = line.indexOf(pat);
            if (pos >= 0)
              {
                char q = line.charAt(pos+patlen);
                int end = line.indexOf(q, pos+patlen+1);
                if (end > 0)
                  {
                    libdir =line.substring(pos+patlen+1, end);
                    break;
                  }
              }
          }
        if (libdir == null)
          libdir = create.libdirSearch(dir);
        File libdirFile = new File(dir, libdir);
        if (! libdirFile.isDirectory())
          create.error("libdir "+libdir+" is not a directory");
        String[] xargs = new String[args.length+1];
        System.arraycopy(args, 0, xargs, 1, args.length);
        xargs[args.length] = "libdir="+libdir;
        pictures.main(xargs);
        create.updateLibdir(libdirFile);
      }
    catch (Throwable ex)
      {
        System.err.println("caught "+ex);
        System.exit(-1);
      }
  }

  public static void help ()
  {
    System.err.println("qalbum usage:");
    System.err.println("  qalbum create [options] \"Title\" [pic1.jpg]...");
    System.err.println("  qalbum new ... is a synonym for qalbum create");
    System.err.println("  qalbum   (generate web pages, if index.xml exists)");
    // System.err.println("  qalbum [-R] tidy");
  }
}
