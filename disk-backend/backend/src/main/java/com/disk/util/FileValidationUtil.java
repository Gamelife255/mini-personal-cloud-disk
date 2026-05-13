package com.disk.util;

import org.apache.tika.Tika;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.Set;

public final class FileValidationUtil {

    private static final Tika TIKA = new Tika();

    private FileValidationUtil() {}

    // ==================== Whitelists ====================

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
        // Images
        ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".ico",
        ".psd", ".tiff", ".tif", ".heic", ".heif",
        // Documents
        ".pdf",
        ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
        // Text / Code
        ".txt", ".csv", ".md", ".rtf",
        ".json", ".xml", ".yml", ".yaml", ".toml", ".ini", ".cfg", ".conf",
        ".properties", ".log",
        ".java", ".py", ".js", ".ts", ".jsx", ".tsx", ".vue",
        ".html", ".htm", ".css", ".scss", ".less",
        ".c", ".cpp", ".h", ".hpp", ".rs", ".go",
        ".sh", ".bat", ".ps1", ".sql",
        // Video
        ".mp4", ".avi", ".mov", ".wmv", ".flv", ".mkv", ".webm", ".m4v",
        // Audio
        ".mp3", ".wav", ".ogg", ".flac", ".aac", ".wma", ".m4a", ".opus",
        // Archives
        ".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz"
    );

    private static final Map<String, String> EXTENSION_TO_CATEGORY = Map.ofEntries(
        Map.entry(".jpg", "image"), Map.entry(".jpeg", "image"), Map.entry(".png", "image"),
        Map.entry(".gif", "image"), Map.entry(".bmp", "image"), Map.entry(".webp", "image"),
        Map.entry(".svg", "image"), Map.entry(".ico", "image"), Map.entry(".psd", "image"),
        Map.entry(".tiff", "image"), Map.entry(".tif", "image"),
        Map.entry(".heic", "image"), Map.entry(".heif", "image"),
        Map.entry(".pdf", "pdf"),
        Map.entry(".doc", "office"), Map.entry(".docx", "office"),
        Map.entry(".xls", "office"), Map.entry(".xlsx", "office"),
        Map.entry(".ppt", "office"), Map.entry(".pptx", "office"),
        Map.entry(".txt", "text"), Map.entry(".csv", "text"), Map.entry(".md", "text"),
        Map.entry(".rtf", "text"),
        Map.entry(".json", "text"), Map.entry(".xml", "text"),
        Map.entry(".yml", "text"), Map.entry(".yaml", "text"),
        Map.entry(".toml", "text"), Map.entry(".ini", "text"),
        Map.entry(".cfg", "text"), Map.entry(".conf", "text"),
        Map.entry(".properties", "text"), Map.entry(".log", "text"),
        Map.entry(".java", "text"), Map.entry(".py", "text"),
        Map.entry(".js", "text"), Map.entry(".ts", "text"),
        Map.entry(".jsx", "text"), Map.entry(".tsx", "text"),
        Map.entry(".vue", "text"), Map.entry(".html", "text"),
        Map.entry(".htm", "text"), Map.entry(".css", "text"),
        Map.entry(".scss", "text"), Map.entry(".less", "text"),
        Map.entry(".c", "text"), Map.entry(".cpp", "text"),
        Map.entry(".h", "text"), Map.entry(".hpp", "text"),
        Map.entry(".rs", "text"), Map.entry(".go", "text"),
        Map.entry(".sh", "text"), Map.entry(".bat", "text"),
        Map.entry(".ps1", "text"), Map.entry(".sql", "text"),
        Map.entry(".mp4", "video"), Map.entry(".avi", "video"), Map.entry(".mov", "video"),
        Map.entry(".wmv", "video"), Map.entry(".flv", "video"), Map.entry(".mkv", "video"),
        Map.entry(".webm", "video"), Map.entry(".m4v", "video"),
        Map.entry(".mp3", "audio"), Map.entry(".wav", "audio"), Map.entry(".ogg", "audio"),
        Map.entry(".flac", "audio"), Map.entry(".aac", "audio"), Map.entry(".wma", "audio"),
        Map.entry(".m4a", "audio"), Map.entry(".opus", "audio"),
        Map.entry(".zip", "archive"), Map.entry(".rar", "archive"), Map.entry(".7z", "archive"),
        Map.entry(".tar", "archive"), Map.entry(".gz", "archive"),
        Map.entry(".bz2", "archive"), Map.entry(".xz", "archive")
    );

    private static final Set<String> INLINE_SAFE_MIME_PREFIXES = Set.of(
        "image/", "video/", "audio/", "text/plain", "application/pdf"
    );

    // ==================== MIME Type Mapping ====================

    private static String mimeTypeToCategory(String mimeType) {
        if (mimeType == null) return "unknown";
        if (mimeType.startsWith("image/"))  return "image";
        if (mimeType.startsWith("video/"))  return "video";
        if (mimeType.startsWith("audio/"))  return "audio";
        if (mimeType.equals("application/pdf")) return "pdf";
        if (mimeType.startsWith("text/"))   return "text";
        if (mimeType.contains("officedocument") ||
            mimeType.equals("application/msword") ||
            mimeType.equals("application/vnd.ms-excel") ||
            mimeType.equals("application/vnd.ms-powerpoint")) return "office";
        if (mimeType.equals("application/rtf")) return "text";
        if (mimeType.equals("application/json") ||
            mimeType.equals("application/xml") ||
            mimeType.equals("application/x-yaml") ||
            mimeType.equals("application/javascript") ||
            mimeType.equals("application/x-sh") ||
            mimeType.equals("application/x-bat") ||
            mimeType.equals("application/x-powershell") ||
            mimeType.equals("application/x-shellscript")) return "text";
        if (mimeType.equals("application/zip") ||
            mimeType.equals("application/gzip") ||
            mimeType.equals("application/x-rar-compressed") ||
            mimeType.equals("application/x-7z-compressed") ||
            mimeType.equals("application/x-tar") ||
            mimeType.equals("application/x-bzip2") ||
            mimeType.equals("application/x-xz")) return "archive";
        return "unknown";
    }

    private static String deriveMimeFromExtension(String extension) {
        if (extension == null) return "application/octet-stream";
        return switch (extension.toLowerCase()) {
            case ".jpg", ".jpeg" -> "image/jpeg";
            case ".png" -> "image/png";
            case ".gif" -> "image/gif";
            case ".bmp" -> "image/bmp";
            case ".webp" -> "image/webp";
            case ".svg" -> "image/svg+xml";
            case ".ico" -> "image/x-icon";
            case ".psd" -> "image/vnd.adobe.photoshop";
            case ".tiff", ".tif" -> "image/tiff";
            case ".heic" -> "image/heic";
            case ".heif" -> "image/heif";
            case ".pdf" -> "application/pdf";
            case ".doc" -> "application/msword";
            case ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            case ".xls" -> "application/vnd.ms-excel";
            case ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            case ".ppt" -> "application/vnd.ms-powerpoint";
            case ".pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation";
            case ".txt", ".md", ".csv", ".log", ".ini", ".cfg", ".conf", ".properties", ".yaml", ".yml", ".toml" -> "text/plain";
            case ".html", ".htm" -> "text/html";
            case ".css" -> "text/css";
            case ".java" -> "text/x-java-source";
            case ".py" -> "text/x-python";
            case ".js" -> "application/javascript";
            case ".ts" -> "application/typescript";
            case ".json" -> "application/json";
            case ".xml" -> "application/xml";
            case ".sh" -> "application/x-sh";
            case ".bat" -> "application/x-bat";
            case ".ps1" -> "application/x-powershell";
            case ".sql" -> "application/sql";
            case ".mp4" -> "video/mp4";
            case ".avi" -> "video/x-msvideo";
            case ".mov" -> "video/quicktime";
            case ".mkv" -> "video/x-matroska";
            case ".webm" -> "video/webm";
            case ".mp3" -> "audio/mpeg";
            case ".wav" -> "audio/wav";
            case ".ogg" -> "audio/ogg";
            case ".flac" -> "audio/flac";
            case ".aac" -> "audio/aac";
            case ".zip" -> "application/zip";
            case ".rar" -> "application/x-rar-compressed";
            case ".7z" -> "application/x-7z-compressed";
            case ".tar" -> "application/x-tar";
            case ".gz" -> "application/gzip";
            case ".bz2" -> "application/x-bzip2";
            case ".xz" -> "application/x-xz";
            default -> "application/octet-stream";
        };
    }

    // ==================== Filename Sanitization ====================

    public static String sanitizeFilename(String filename) {
        if (filename == null) return "";
        String sanitized = filename.replace("\0", "");
        sanitized = sanitized.replace("/", "").replace("\\", "");
        sanitized = sanitized.replaceAll("[\\x00-\\x1F]", "");
        sanitized = sanitized.replaceAll("^\\.+", "");
        sanitized = sanitized.replaceAll("\\.{2,}", ".");
        sanitized = sanitized.trim();
        return sanitized.isEmpty() ? "" : sanitized;
    }

    // ==================== Core Validation ====================

    public static ValidationResult validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return ValidationResult.fail("文件不能为空");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.isBlank()) {
            return ValidationResult.fail("文件名不能为空");
        }

        // Step 1: Sanitize filename
        String sanitizedName = sanitizeFilename(originalFilename);
        if (sanitizedName.isEmpty()) {
            return ValidationResult.fail("文件名包含非法字符");
        }

        // Step 2: Extract and validate extension
        int dotIndex = sanitizedName.lastIndexOf('.');
        if (dotIndex < 0 || dotIndex == sanitizedName.length() - 1) {
            return ValidationResult.fail("不支持无扩展名的文件");
        }
        String extension = sanitizedName.substring(dotIndex).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            return ValidationResult.fail("不支持的文件类型: " + extension);
        }
        String expectedCategory = EXTENSION_TO_CATEGORY.get(extension);

        // Step 3: Detect real MIME via Tika magic bytes
        String detectedMime;
        try (InputStream in = file.getInputStream()) {
            detectedMime = TIKA.detect(in);
        } catch (IOException e) {
            return ValidationResult.fail("无法读取文件内容");
        }

        // Step 4: Fallback to Files.probeContentType if Tika returned generic
        if (detectedMime == null || detectedMime.equals("application/octet-stream")) {
            Path tempFile = null;
            try {
                tempFile = Files.createTempFile("upload-validate-", extension);
                file.transferTo(tempFile.toFile());
                String probeMime = Files.probeContentType(tempFile);
                if (probeMime != null && !probeMime.equals("application/octet-stream")) {
                    detectedMime = probeMime;
                }
            } catch (IOException ignored) {
            } finally {
                if (tempFile != null) {
                    try { Files.deleteIfExists(tempFile); } catch (IOException ignored) { }
                }
            }
        }

        // Step 5: Verify category match
        String detectedCategory = mimeTypeToCategory(detectedMime);
        boolean categoryOk = expectedCategory.equals(detectedCategory)
            || ("text".equals(expectedCategory) && "office".equals(detectedCategory))
            || ("office".equals(expectedCategory) && "text".equals(detectedCategory))
            || "unknown".equals(detectedCategory);

        if (!categoryOk) {
            return ValidationResult.fail(String.format(
                "文件内容与扩展名不匹配 (扩展名: %s, 实际类型: %s)",
                extension, detectedMime));
        }

        // Step 6: Determine final MIME
        String finalMime;
        if (detectedMime != null && !detectedMime.equals("application/octet-stream")) {
            finalMime = detectedMime;
        } else {
            finalMime = deriveMimeFromExtension(extension);
        }

        return ValidationResult.success(sanitizedName, finalMime, extension);
    }

    // ==================== Path Traversal Protection ====================

    public static Path resolveSafePath(String uploadRoot, String parentFolderPath,
                                        String newFileName) throws IOException {
        Path root = Paths.get(uploadRoot).toRealPath();
        Path parent = root;

        if (parentFolderPath != null && !parentFolderPath.isEmpty()) {
            Path candidate = Paths.get(parentFolderPath).toRealPath();
            if (candidate.startsWith(root)) {
                parent = candidate;
            }
        }

        Path resolved = parent.resolve(newFileName).normalize();
        if (!resolved.startsWith(root)) {
            throw new SecurityException("文件路径超出允许范围");
        }
        return resolved;
    }

    // ==================== Inline Preview Safety ====================

    public static boolean isInlineSafe(String mimeType) {
        if (mimeType == null) return false;
        for (String prefix : INLINE_SAFE_MIME_PREFIXES) {
            if (mimeType.startsWith(prefix)) return true;
        }
        return false;
    }

    // ==================== Result Record ====================

    public record ValidationResult(
        boolean valid,
        String sanitizedFileName,
        String detectedMimeType,
        String extension,
        String errorMessage
    ) {
        public static ValidationResult success(String name, String mime, String ext) {
            return new ValidationResult(true, name, mime, ext, null);
        }
        public static ValidationResult fail(String error) {
            return new ValidationResult(false, null, null, null, error);
        }
    }
}
