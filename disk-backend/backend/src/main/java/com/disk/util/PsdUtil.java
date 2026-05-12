package com.disk.util;

import com.twelvemonkeys.imageio.plugins.psd.PSDImageReader;
import com.twelvemonkeys.imageio.plugins.psd.PSDImageReaderSpi;
import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.FileImageInputStream;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.Iterator;

public class PsdUtil {

    static {
        // 注册PSD插件
        ImageIO.scanForPlugins();
    }

    public static BufferedImage psdToImage(File psdFile) throws Exception {
        // 使用ImageIO读取PSD文件
        Iterator<javax.imageio.ImageReader> readers = ImageIO.getImageReadersByFormatName("psd");
        if (readers.hasNext()) {
            ImageReader reader = readers.next();
            try (FileImageInputStream fis = new FileImageInputStream(psdFile)) {
                reader.setInput(fis);
                return reader.read(0);
            } finally {
                reader.dispose();
            }
        }
        throw new RuntimeException("PSD reader not available");
    }

    public static void psdToPng(File psdFile, File outputFile) throws Exception {
        BufferedImage image = psdToImage(psdFile);
        ImageIO.write(image, "png", outputFile);
    }

    public static boolean isPsdFile(String fileName) {
        if (fileName == null) {
            return false;
        }
        String lower = fileName.toLowerCase();
        return lower.endsWith(".psd");
    }
}
