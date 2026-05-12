package com.disk.util;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class VerificationCodeStore {

    private static class CodeEntry {
        String code;
        long expireAt;

        CodeEntry(String code, long expireAt) {
            this.code = code;
            this.expireAt = expireAt;
        }
    }

    // key: email, value: code entry
    private final Map<String, CodeEntry> store = new ConcurrentHashMap<>();

    private static final long EXPIRE_MS = 15 * 60 * 1000; // 15 minutes

    public void save(String email, String code) {
        store.put(email, new CodeEntry(code, System.currentTimeMillis() + EXPIRE_MS));
    }

    public boolean verify(String email, String code) {
        CodeEntry entry = store.get(email);
        if (entry == null) {
            return false;
        }
        if (System.currentTimeMillis() > entry.expireAt) {
            store.remove(email);
            return false;
        }
        if (!entry.code.equals(code)) {
            return false;
        }
        store.remove(email); // one-time use
        return true;
    }

    public void remove(String email) {
        store.remove(email);
    }
}
