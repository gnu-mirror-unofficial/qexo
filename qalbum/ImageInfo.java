package qalbum;
import com.drew.imaging.jpeg.*;
import com.drew.metadata.*;
import com.drew.metadata.exif.*;
import com.drew.metadata.jpeg.*;
import java.io.*;

/** Information relating to and extracted from a JPEG image. */

public class ImageInfo
{
  Metadata metadata;
  Directory exifDirectory;
  int width, height;
  File jpegFile;
  String filename;

  public static ImageInfo readMetadata (String filename)
    throws Throwable
  {
    return readMetadata(new File(filename), filename);
  }

  public static ImageInfo readMetadata (File jpegFile)
    throws Throwable
  {
    return readMetadata(jpegFile, jpegFile.getPath());
  }

  public static ImageInfo readMetadata (File jpegFile, String filename)
    throws Throwable
  {
    Metadata metadata = JpegMetadataReader.readMetadata(jpegFile);
    Directory exifDirectory = metadata.getDirectory(ExifDirectory.class);
    Directory jpegDirectory = metadata.getDirectory(JpegDirectory.class);
    ImageInfo info = new ImageInfo();
    info.metadata = metadata;
    info.exifDirectory = exifDirectory;
    info.width = jpegDirectory.getInt(JpegDirectory.TAG_JPEG_IMAGE_WIDTH);
    info.height = jpegDirectory.getInt(JpegDirectory.TAG_JPEG_IMAGE_HEIGHT);
    info.filename = filename;
    info.jpegFile = jpegFile;
    return info;
  }

  public String getExifString (int tag)
  {
    return exifDirectory.getString(tag);
  }

  public String getExifDescription (int tag)
  {
    return getDescription(tag, exifDirectory);
  }

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
    //String value = getExifString(tag);
    String value = getDescription(tag, exifDirectory);
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
          = exifDirectory.getInt(ExifDirectory.TAG_FOCAL_PLANE_UNIT);
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
        focalplaneXRes = exifDirectory.getDouble(ExifDirectory.TAG_FOCAL_PLANE_X_RES);
        CCDwidth = (float) (((int) (100 * width * focalplaneUnits / focalplaneXRes + 0.5)) / 100.00);
      }
    catch (Throwable ex)
      {
      }

    StringBuffer sbuf = new StringBuffer();

    sbuf.append("File name:     ");  sbuf.append(filename);  sbuf.append('\n');

    sbuf.append("File size:     ");
    sbuf.append(jpegFile.length());  sbuf.append(" bytes\n");
    sbuf.append("File date:     ");
    sbuf.append(new java.util.Date(jpegFile.lastModified()));
    sbuf.append('\n');

    appendExifString("Camera make:   ", ExifDirectory.TAG_MAKE, sbuf);
    appendExifString("Camera model:  ", ExifDirectory.TAG_MODEL, sbuf);

    //appendExifString("Orientation:   ", ExifDirectory.TAG_ORIENTATION, sbuf);

    appendExifString("Date/Time:     ", ExifDirectory.TAG_DATETIME, sbuf);

    sbuf.append("Resolution:    "); sbuf.append(width);
    sbuf.append(" x "); sbuf.append(height); sbuf.append('\n');

    double focalLength = exifDouble(ExifDirectory.TAG_FOCAL_LENGTH);
    String focalLengthDesc
      = getExifDescription(ExifDirectory.TAG_FOCAL_LENGTH);
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

    if (exifDirectory.containsTag(ExifDirectory.TAG_SHUTTER_SPEED))
      appendExifString("Shutter speed: ", ExifDirectory.TAG_SHUTTER_SPEED, sbuf);
    else
      appendExifString("Exposure time: ", ExifDirectory.TAG_EXPOSURE_TIME, sbuf);
    appendExifString("Aperture:      ", ExifDirectory.TAG_FNUMBER, sbuf);
    appendExifString("ISO equiv.:    ", ExifDirectory.TAG_ISO_EQUIVALENT, sbuf);
    appendExifString("Metering mode: ", ExifDirectory.TAG_METERING_MODE, sbuf);
    appendExifString("Exposure:      ", ExifDirectory.TAG_EXPOSURE_PROGRAM, sbuf);
    appendExifString("JPG quality:   ", ExifDirectory.TAG_COMPRESSION_LEVEL, sbuf);

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