// Based on http://developer.java.sun.com/developer/TechTips/1999/tt1021.html

package qalbum;

import java.awt.Image;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.OutputStream;
import java.io.FileOutputStream;
import javax.swing.ImageIcon;
import javax.imageio.ImageIO;
//import com.sun.image.codec.jpeg.JPEGCodec;
//import com.sun.image.codec.jpeg.JPEGImageEncoder;
import gnu.kawa.io.Path;

class Thumbnail {
    public static void main(String[] args) {
        createThumbnail(Path.valueOf(args[0]),
                        Path.valueOf(args[1]),
                        Integer.parseInt(args[2]));
    }

    /**
     * Reads an image in a file and creates 
     * a thumbnail in another file.
     * @param orig The name of image file.
     * @param thumb The name of thumbnail file.  
     * Will be created if necessary.
     * @param maxDim The width and height of 
     * the thumbnail must 
     * be maxDim pixels or less.
     */
  public static void createThumbnail(Path orig, Path thumb, int maxDim)
  {
        try {
            // Get the image from a file.
            Image inImage
              = new ImageIcon(orig.toURL()).getImage();

            int inW = inImage.getWidth(null);
            int inH = inImage.getHeight(null);
            int scaledW, scaledH;
            if (inW > inH) {
              scaledW = maxDim;
              scaledH = (maxDim * inH) / inW;
            }
            else if (inW < inH) {
              scaledH = maxDim;
              scaledW = (maxDim  * inW) / inH;
            }
            else {
              scaledH = scaledW = maxDim;
            }

            // Create an image buffer in which to paint on.
            BufferedImage outImage = 
              new BufferedImage(scaledW, scaledH,
                BufferedImage.TYPE_INT_RGB);

            // Paint image.
            Graphics2D g2d = 
             outImage.createGraphics();
            g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            g2d.drawImage(inImage, 0, 0, scaledW, scaledH, null);
            g2d.dispose();

            // JPEG-encode the image 
            //and write to file.
            OutputStream os = thumb.openOutputStream();
            ImageIO.write(outImage, "jpeg", os);
            //JPEGImageEncoder encoder = 
            //  JPEGCodec.createJPEGEncoder(os);
            // encoder.encode(outImage);
            os.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
  
/*
You run the program like this:

    java Thumbnail <original.{gif,jpg}> 
         <thumbnail.jpg> <maxDim>
*/
