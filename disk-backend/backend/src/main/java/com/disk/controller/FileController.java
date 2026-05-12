package com.disk.controller;

import com.disk.entity.File;
import com.disk.service.FileService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/file")
public class FileController {
    @Autowired
    private FileService fileService;

    @PostMapping("/upload")
    public File upload(@RequestBody File file) {
        return fileService.upload(file);
    }

    @GetMapping("/download/{id}")
    public File download(@PathVariable Long id) {
        return fileService.download(id);
    }

    @GetMapping("/list")
    public List<File> list(@RequestParam Long userId, @RequestParam(required = false) Long parentId) {
        return fileService.list(userId, parentId);
    }

    @PutMapping("/rename/{id}")
    public File rename(@PathVariable Long id, @RequestParam String newName) {
        return fileService.rename(id, newName);
    }

    @DeleteMapping("/{id}")
    public int delete(@PathVariable Long id) {
        return fileService.delete(id);
    }
}
