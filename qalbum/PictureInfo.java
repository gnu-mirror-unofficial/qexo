package qalbum;
import java.io.*;

public class PictureInfo
{
  static boolean autoScale = true;

  String label;
  ImageInfo original;
  /** Same as original, unless rotated/cropped etc.
   * (Though in the future we might add a copyright notice.). */
  ImageInfo large;
  /** Medium-sized image suitable as the main image on a page.
   * Width about 740 pixels. */
  ImageInfo medium;
  /** Thumbnail image.  Width about 240 pixels. */
  ImageInfo thumbnail;

  public static PictureInfo getImages(String label,
                                      String rotated,
                                      String image)
    throws Throwable
  {
    PictureInfo info = new PictureInfo();
    info.label = label;
    info.original = ImageInfo.readMetadata(image);
    String main = image;
    int dot = image.lastIndexOf('.');
    int flen = image.length();
    if (dot <= 0 || dot > flen - 4 || dot < flen - 5)
      throw new RuntimeException("missng type type suffix for image  file name '"+image+"'");
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
        
        String rotname = base+'r'+suffix;
        File rotfile = new File(rotname);
        if (rotfile.exists())
          info.large = ImageInfo.readMetadata(rotfile, rotname);
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
            info.large = ImageInfo.readMetadata(rotfile, rotname);
          }
        else
          {
            System.err.println("rotated file "+rotname+" missing");
            info.large = info.original;
          }
      }
    else
      info.large = info.original;
    String large_image = info.large.filename;
    info.thumbnail = forceReadMetadata(base+'t'+suffix, large_image, 240);
    info.medium = forceReadMetadata(base+'p'+suffix, large_image, 740);
    return info;
  }

  static ImageInfo forceReadMetadata (String filename, String orig, int maxDim)
    throws Throwable
  {
    File file = new File(filename);
    if (! file.exists())
      {
        if (! autoScale)
          return null;
        // FIXME also print size.
        System.err.println("scaling "+orig+" to "+filename+" maxSize:"+maxDim);
        Thumbnail.createThumbnail(orig, filename, maxDim);
      }
    return ImageInfo.readMetadata(file, filename);
  }

  boolean hasThumbnail ()
  {
    return thumbnail != null;
  }

  public ImageInfo findImageInfo (String filename)
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

  public String getScaledFile (String scaleName)
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

  public int getWidthFor (String filename)
  {
    return findImageInfo(filename).width;
  }

  public int getHeightFor (String filename)
  {
    return findImageInfo(filename).height;
  }

  public String getSizeDescription (String filename)
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
        String filename = info.filename;
        int namelen = filename.length();
        if (namelen > 5)
          {
            char kind = filename.charAt(namelen-5);
            if (kind == 'r' || kind == 'p' || kind == 't')
              {
                filename = filename.substring(0, namelen-5) + ".jpg";
                File orig = new File(filename);
                if (orig.exists())
                  original = info = ImageInfo.readMetadata(orig, filename);
              }
          }
      }
    return info.getCommonValues();
  }
}
