import java.io.*;
import java.util.*;
import javax.imageio.*;
import javax.imageio.stream.*;

public class MakeXml
{
  public static void main (String[] args) throws IOException
  {
    String title = args[0];
    File indexFile = new File("index.xml");
    if (indexFile.exists())
      {
	System.err.println("The file index.xml already exists.");
	System.err.println("Delete it first if you're sure you don't want it.");
	System.exit(-1);
      }
    PrintWriter out = new PrintWriter(new FileWriter(indexFile));

    out.println("<?xml version=\"1.0\"?>");
    out.println("<group>");
    out.println("<title>" + title + "</title>");

    int iend = args.length;
    for (int i = 1;  i < iend;  i++)
      {
	String filename = args[i];
	File file =  new File(filename);
	String base = file.getName();
	int dotIndex = base.lastIndexOf('.');
	if (dotIndex > 0)
	  base = base.substring(0, dotIndex);
	Iterator readers = ImageIO.getImageReadersByFormatName("jpg");
	ImageReader reader = (ImageReader) readers.next();
	ImageInputStream iis = ImageIO.createImageInputStream(file);
	reader.setInput(iis, true);
	int width = reader.getWidth(0);
	int height = reader.getHeight(0);
	out.print("<picture id=\"");  out.print(base);
	out.print("\" width=\"");  out.print(width);
	out.print("\" height=\"");  out.print(height);
	out.println("\">");
	String tag = width <= 700 || height <= 700 ? "image" : "full-image";
	//System.err.println("file: "+filename+" width: "+width+" height: "+height+" tag:"+tag);
	out.print('<');  out.print(tag);  out.print('>');  out.print(filename);
	out.print("</");  out.print(tag);  out.println('>');
	out.println("</picture>");
      }
    out.println("</group>");
    out.close();
  }
}
