package qalbum;
import com.drew.imaging.jpeg.*;
import com.drew.metadata.*;
import com.drew.metadata.exif.*;
import com.drew.metadata.jpeg.*;
import java.io.*;
import gnu.kawa.io.Path;

/** Information relating to and extracted from a JPEG image. */

public class ImageInfo
{
  Metadata metadata;
  Directory exifDirectory;
  Directory exif0Directory;
  int width, height;
  Path filename;

  public static ImageInfo readMetadata (Object filename)
    throws Throwable
  {
    Path path = Path.valueOf(filename);
    InputStream in
      = new BufferedInputStream(path.openInputStream());
    com.drew.metadata.Metadata metadata = JpegMetadataReader.readMetadata(in);
    Directory exifDirectory =
        metadata.getFirstDirectoryOfType(ExifSubIFDDirectory.class);
    Directory exif0Directory =
        metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);
    Directory jpegDirectory = metadata.getFirstDirectoryOfType(JpegDirectory.class);
    ImageInfo info = new ImageInfo();
    info.metadata = metadata;
    info.exifDirectory = exifDirectory;
    info.exif0Directory = exif0Directory;
    info.width = jpegDirectory.getInt(JpegDirectory.TAG_IMAGE_WIDTH);
    info.height = jpegDirectory.getInt(JpegDirectory.TAG_IMAGE_HEIGHT);
    info.filename = path;
    return info;
  }

  public String getExifString (int tag)
  {
    return exifDirectory == null ? null : exifDirectory.getString(tag);
  }

  public static int minRating = 3;

  public boolean dontSkip()
  {
    long rating = exifLong(0x4746);
    return rating == 0 || rating >= minRating;
  }

  /** Get image "caption" from the EXIF "user comment."
   * The caption is the first line.
   */
  public String getCaption ()
  {
    String comment = getExifDescription(ExifSubIFDDirectory.TAG_USER_COMMENT);
    /*
    String commente = null;
    if (exifDirectory instanceof ExifDirectory)
      {
        try{
      commente = ((ExifDirectory) exifDirectory).getUserComment();
      System.err.println("UserComment "+commente);
        } catch (Throwable ex) { }

      }
    */

    /*
    byte[] commentb;
    try
      {
        commentb = exifDirectory.getByteArray(TAG_USER_COMMENT);
        System.err.print("comment [");
        for (int i = 0; i < commentb.length;  i++) {
          if (i > 0) System.err.print(", ");
          System.err.print(0xFF & commentb[i]);
        }
        System.err.println("]");
      }
    catch (Throwable ex)
      {
        System.err.println("caught "+ex);
        commentb = null;
      }
    if (commentb == null)
      System.err.println("commentb null");
    else
      System.err.println("commentb len:"+commentb.length);
    */
    if (comment != null && comment.length() > 0)
      {
        //System.err.println("caption/user-comment:"+comment);
        int nl = comment.indexOf('\n');
        return nl < 0 ? comment : comment.substring(0, nl);
      }
    return "";
  }

  public String getDateTime ()
  {
    return getExifDescription(ExifSubIFDDirectory.TAG_DATETIME);
  }

  /** Get image "text" description from the EXIF "user comment."
   * Leave out the first line, which is the caption.
   */

  public String getText ()
  {
    String comment = getExifDescription(ExifSubIFDDirectory.TAG_USER_COMMENT);
    if (comment != null && comment.length() > 0)
      {
        int nl = comment.indexOf('\n');
        return nl < 0 ? "" : comment.substring(nl);
      }
    return "";
  }

  public String getExifDescription (int tag)
  {
    String value = getDescription(tag, exifDirectory);
    if (value == null)
        value = getDescription(tag, exif0Directory);
    return value;
  }

  /*
  public byte[] getExifBytes (int tag)
  {
    return exifDirectory.getByteArray(tag);
  }
  */

  public String getDescription (int tag, Directory directory)
  {
    String value;
    try
      {
        return directory.getDescription(tag);
      }
    catch (Throwable ex)
      {
        return getExifString(tag);
      }
  }

  public void appendExifString (String label, int tag, StringBuffer sbuf)
  {
    String value = getExifDescription(tag);
    if (value == null)
      return;
    sbuf.append(label);
    sbuf.append(value);
    sbuf.append('\n');
  }

  public double exifDouble (int tag)
  {
    try
      {
        return exifDirectory.getDouble(tag);
      }
    catch (Throwable ex)
      {
        return 0;
      }
  }

  public long exifLong (int tag)
  {
    try
      {
        return exifDirectory.getLong(tag);
      }
    catch (Throwable ex)
      {
        return 0;
      }
  }

  public int getRating ()
  {
    return (int) exifLong(0x4746);
  }

  public static String readCommonValues (String filename)
    throws Throwable
  {
    return readMetadata(filename).getCommonValues();
  }

  public String getCommonValues ()
  {
    double focalplaneUnits = 0;
    double focalplaneXRes = 0;
    float CCDwidth = 0;
    try
      {
        int focalplaneUnitCode
          = exifDirectory.getInt(ExifSubIFDDirectory.TAG_FOCAL_PLANE_RESOLUTION_UNIT);
        switch (focalplaneUnitCode)
          {
          case 1: focalplaneUnits = 25.4; break; // inch
          case 2:
            // According to the information I was using, 2 means meters.
            // But looking at the Cannon powershot's files, inches is the only
            // sensible value.
            focalplaneUnits = 25.4;
            break;
          case 3: focalplaneUnits = 10;   break;  // centimeter
          case 4: focalplaneUnits = 1;    break;  // milimeter
          case 5: focalplaneUnits = .001; break;  // micrometer
          default:  focalplaneUnits = 0;
          }
        focalplaneXRes = exifDirectory.getDouble(ExifSubIFDDirectory.TAG_FOCAL_PLANE_X_RESOLUTION);
        CCDwidth = (float) (((int) (100 * width * focalplaneUnits / focalplaneXRes + 0.5)) / 100.00);
      }
    catch (Throwable ex)
      {
      }

    StringBuffer sbuf = new StringBuffer();

    sbuf.append("File name:     ");  sbuf.append(filename);  sbuf.append('\n');

    sbuf.append("File size:     ");    sbuf.append(filename.getContentLength());  sbuf.append(" bytes\n");
    sbuf.append("File date:     ");
    sbuf.append(new java.util.Date(filename.getLastModified()));
    sbuf.append('\n');

    appendExifString("Camera make:   ", ExifSubIFDDirectory.TAG_MAKE, sbuf);
    appendExifString("Camera model:  ", ExifSubIFDDirectory.TAG_MODEL, sbuf);

    //appendExifString("Orientation:   ", ExifSubIFDDirectory.TAG_ORIENTATION, sbuf);

    appendExifString("Date/Time:     ", ExifSubIFDDirectory.TAG_DATETIME, sbuf);

    sbuf.append("Resolution:    "); sbuf.append(width);
    sbuf.append(" x "); sbuf.append(height); sbuf.append('\n');

    double focalLength = exifDouble(ExifSubIFDDirectory.TAG_FOCAL_LENGTH);
    String focalLengthDesc
      = getExifDescription(ExifSubIFDDirectory.TAG_FOCAL_LENGTH);
    if (focalLength != 0 && focalLengthDesc != null)
      {
        sbuf.append("Focal length:  ");
        sbuf.append(focalLengthDesc);
        if (CCDwidth > 0)
          {
            sbuf.append(" (35mm equivalent: ");
            sbuf.append((int)(focalLength/CCDwidth*35 + 0.5));
            sbuf.append("mm)");
          }
        sbuf.append('\n');
      }

    if (CCDwidth > 0)
      {
        sbuf.append("CCD width:     ");
        sbuf.append(CCDwidth);
        sbuf.append("mm\n");
      }

    if (exifDirectory != null
        && exifDirectory.containsTag(ExifSubIFDDirectory.TAG_SHUTTER_SPEED))
      appendExifString("Shutter speed: ", ExifSubIFDDirectory.TAG_SHUTTER_SPEED, sbuf);
    else
      appendExifString("Exposure time: ", ExifSubIFDDirectory.TAG_EXPOSURE_TIME, sbuf);
    appendExifString("Aperture:      ", ExifSubIFDDirectory.TAG_FNUMBER, sbuf);
    appendExifString("ISO equiv.:    ", ExifSubIFDDirectory.TAG_ISO_EQUIVALENT, sbuf);
    appendExifString("Metering mode: ", ExifSubIFDDirectory.TAG_METERING_MODE, sbuf);
    appendExifString("Exposure:      ", ExifSubIFDDirectory.TAG_EXPOSURE_PROGRAM, sbuf);
    appendExifString("JPG quality:   ", ExifSubIFDDirectory.TAG_COMPRESSED_AVERAGE_BITS_PER_PIXEL, sbuf);
    appendExifString("Rating:   ", 0x4746, sbuf);

    return sbuf.toString();
  }

  public String toString ()
  {
    return "ImageInfo["+filename+"]";
  }

  public static void main (String[] args)
    throws Throwable
  {
    for (int i = 0;  i < args.length;  i++)
      {
        System.err.print(readCommonValues(args[i]));
        //String arg = args[i];
        //ImageInfo info = readMetadata(arg);
        //System.err.print(info.getCommonValues());
      }
  }
}
