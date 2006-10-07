package qalbum;
import java.io.*;

public class PictureInfo
{
  String label;
  ImageInfo thumbnail;
  ImageInfo medium;
  ImageInfo large;
  ImageInfo original;

  public static PictureInfo make(String label, String small,
                                 String medium, String large)
    throws Throwable
  {
    PictureInfo info = new PictureInfo();
    info.label = label;
    if (small != null && small.length() > 0)
      info.thumbnail = ImageInfo.readMetadata(small);
    if (medium != null && medium.length() > 0)
      info.medium = ImageInfo.readMetadata(medium);
    if (large != null && large.length() > 0)
      info.large = ImageInfo.readMetadata(large);
    return info;
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
