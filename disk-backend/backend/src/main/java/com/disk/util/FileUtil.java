package com.disk.util;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

public class FileUtil {
    private static final String UPLOAD_DIR = "./uploads";

    public static String generateFilePath(String originalFileName) {
        String extension = getFileExtension(originalFileName);
        String fileName = UUID.randomUUID().toString() + extension;
        return UPLOAD_DIR + "/" + fileName;
    }

    public static String getFileExtension(String fileName) {
        if (fileName == null || !fileName.contains(".")) {
            return "";
        }
        return fileName.substring(fileName.lastIndexOf("."));
    }

    public static String getFileType(String fileName) {
        String extension = getFileExtension(fileName).toLowerCase();
        if (extension.matches("\\.(jpg|jpeg|png|gif|bmp)")) {
            return "image";
        } else if (extension.matches("\\.(doc|docx)")) {
            return "document";
        } else if (extension.matches("\\.(pdf)")) {
            return "pdf";
        } else if (extension.matches("\\.(mp4|avi|mov)")) {
            return "video";
        } else if (extension.matches("\\.(mp3|wav)")) {
            return "audio";
        } else if (extension.matches("\\.(zip|rar|7z)")) {
            return "archive";
        } else {
            return "other";
        }
    }

    public static long getFileSize(String filePath) {
        File file = new File(filePath);
        return file.exists() ? file.length() : 0;
    }

    public static boolean createDirectory(String path) {
        try {
            Path dirPath = Paths.get(path);
            if (!Files.exists(dirPath)) {
                Files.createDirectories(dirPath);
                return true;
            }
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static boolean deleteFile(String filePath) {
        File file = new File(filePath);
        return file.exists() && file.delete();
    }

    public static String formatFileSize(long size) {
        if (size < 1024) {
            return size + " B";
        } else if (size < 1024 * 1024) {
            return String.format("%.2f KB", size / 1024.0);
        } else if (size < 1024 * 1024 * 1024) {
            return String.format("%.2f MB", size / (1024.0 * 1024));
        } else {
            return String.format("%.2f GB", size / (1024.0 * 1024 * 1024));
        }
    }
}
