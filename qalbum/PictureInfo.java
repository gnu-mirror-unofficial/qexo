package qalbum;
import java.io.*;
import java.net.URI;
import gnu.text.*;
import gnu.kawa.io.Path;

public class PictureInfo
{

  public static void print(String prefix, Object value) {
    System.err.print(prefix);
    System.err.print(value);
    if (value != null) {
      System.err.print(" type: ");
      System.err.print(value.getClass().getName());
    }
  }
  public static void println(String prefix, Object value) {
    print(prefix, value);
    System.err.println();
  }

  static boolean autoScale = true;

  Object key;
  String label;
  String caption;
  Object text;
  ImageInfo original;
  /** Same as original, unless rotated/cropped etc.
   * (Though in the future we might add a copyright notice.). */
  ImageInfo large;
  /** Medium-sized image suitable as the main image on a page.
   * Width about 740 pixels. */
  ImageInfo medium;
  /** Thumbnail image.  Width about 240 pixels. */
  ImageInfo thumbnail;

  public boolean dontSkip ()
  {
    return original == null || original.dontSkip();
  }

  public static PictureInfo getImages(Object key, String label,
                                      String rotated,
                                      Object path, String caption)
    throws Throwable
  {
    if (path instanceof URI)
      path = new File((URI) path);
    String image = path.toString();
    PictureInfo info = getImages(label, rotated, ImageInfo.readMetadata(image));
    if (caption != null && caption.length() == 0)
      caption = null;
    info.caption = caption;
    info.key = key;
    return info;
  }
  public static PictureInfo getImages(String label,
                                      String rotated,
                                      ImageInfo original)
    throws Throwable
  {
    PictureInfo info = new PictureInfo();
    info.label = label;
    info.original = original;
    if (! info.dontSkip())
      return info;
    String image = original.filename.toString();
    int dot = image.lastIndexOf('.');
    int flen = image.length();
    if (dot <= 0 || dot > flen - 4 || dot < flen - 5)
      throw new RuntimeException("missng type type suffix for image  file name '"+image+"'");
    boolean forceReScale = false;
    String suffix = image.substring(dot);
    boolean alreadyRotated;
    String base = image.substring(0, dot);
    if (alreadyRotated = (image.charAt(dot - 1) == 'r'))
      {
        dot--;
        base = image.substring(0, dot);
        info.large = info.original;
      }
    else if (rotated.length() != 0)
      {
        
        Path rotname = Path.valueOf(base+'r'+suffix);
        if (rotname.exists())
          info.large = ImageInfo.readMetadata(rotname);
        else if (autoScale)
          {
            String rot;
            if (rotated.equals("left"))
              rot = "90";
            else if (rotated.equals("right"))
              rot = "270";
            else
              throw new Error("unknown rotation "+rotated+" f0r "+label);
            System.err.println("rotating "+image+" by "+rot+" yielding "+rotname);
            String[] jpegtranArgs = {"/bin/sh", "-c",
                                     "jpegtran -rotate "+rot+" -trim "+image+">"+rotname};
            Process process = Runtime.getRuntime().exec(jpegtranArgs);
            int exitCode = process.waitFor();
            if (exitCode != 0)
              System.err.println("Unexpected jpegtran exitCode:"+exitCode);
            info.large = ImageInfo.readMetadata(rotname);
            forceReScale = true;
          }
        else
          {
            System.err.println("rotated file "+rotname+" missing");
            info.large = info.original;
          }
      }
    else
      info.large = info.original;
    Path large_image = info.large.filename;
    info.thumbnail = forceReadMetadata(base+'t'+suffix, large_image,
                                       240, forceReScale);
    if (info.large.width <= 740 && info.large.height <= 740)
      {
        info.medium = info.large;
        info.large = null;
      }
    else
      info.medium = forceReadMetadata(base+'p'+suffix, large_image,
                                      740, forceReScale);
    return info;
  }

  static ImageInfo forceReadMetadata (String filename, Path orig,
                                      int maxDim, boolean forceReScale)
    throws Throwable
  {
    Path path = Path.valueOf(filename);
    if (forceReScale || ! path.exists())
      {
        if (! autoScale)
          return null;
        // FIXME also print size.
        System.err.println("scaling "+orig+" to "+filename+" maxSize:"+maxDim);
        Thumbnail.createThumbnail(orig, path, maxDim);
      }
    return ImageInfo.readMetadata(path);
  }

  public int getRating ()
  {
    return original == null ? 0 : original.getRating();
  }

  public Object getKey ()
  {
    return key;
  }

  public String getLabel ()
  {
    return label;
  }

  public String getCaption ()
  {
    if (caption == null)
      caption = original == null ? "" : original.getCaption();
    return caption;
  }

  public String getDateTime ()
  {
    return original == null ? "" : original.getDateTime();
  }

  boolean hasThumbnail ()
  {
    return thumbnail != null;
  }

  public ImageInfo findImageInfo (Path filename)
  {
    if (original != null && filename.equals(original.filename))
      return original;
    else if (large != null && filename.equals(large.filename))
      return large;
    else if (medium != null && filename.equals(medium.filename))
      return medium;
    else if (thumbnail != null && filename.equals(thumbnail.filename))
      return thumbnail;
    else
      return null;
  }

  public ImageInfo findScaledImage (String scaleName)
  {
    if (scaleName == null || scaleName.length() == 0)
      return original;
    if (scaleName.charAt(0) == 'o')
      return original;
    if (scaleName.charAt(0) == 'l')
      return large;
    if (scaleName.charAt(0) == 't')
      return thumbnail;
    if (scaleName.charAt(0) == 'm' || scaleName.charAt(0) == 'p')
      return medium;
    return null;
  }

  public boolean getScaledExists (String scaleName)
  {
    return findScaledImage(scaleName) != null;
  }

  public Path getScaledFile (String scaleName)
  {
    return findScaledImage(scaleName).filename;
  }

  public int getScaledWidth (String scaleName)
  {
    return findScaledImage(scaleName).width;
  }

  public int getScaledHeight (String scaleName)
  {
    return findScaledImage(scaleName).height;
  }

  public int getWidthFor (Path filename)
  {
    return findImageInfo(filename).width;
  }

  public int getHeightFor (Path filename)
  {
    return findImageInfo(filename).height;
  }

  public String getSizeDescription (Path filename)
  {
    StringBuffer sbuf = new StringBuffer();
    ImageInfo info = findImageInfo(filename);
    if (info != null)
      {
        sbuf.append(" (");
        sbuf.append(info.width);
        sbuf.append('x');
        sbuf.append(info.height);
        sbuf.append(')');
      }
    return sbuf.toString();
  }

  public String getImageDescription ()
    throws Throwable
  {
    ImageInfo info = original != null ? original
      : large != null? large
      : medium != null ? medium
      : thumbnail != null ? thumbnail
      : null;
    if (info != original)
      {
        String filename = info.filename.toString();;
        int namelen = filename.length();
        if (namelen > 5)
          {
            char kind = filename.charAt(namelen-5);
            if (kind == 'r' || kind == 'p' || kind == 't')
              {
                filename = filename.substring(0, namelen-5) + ".jpg";
                Path path = Path.valueOf(filename);
                if (path.exists())
                  original = info = ImageInfo.readMetadata(path);
              }
          }
      }
    return info.getCommonValues();
  }
}
