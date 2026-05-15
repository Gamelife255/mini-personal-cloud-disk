package com.disk.util;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
public class VerificationCodeStore {

    @Autowired
    private StringRedisTemplate redisTemplate;

    private static final String KEY_PREFIX = "verify_code:";
    private static final Duration TTL = Duration.ofMinutes(15);

    public void save(String email, String code) {
        redisTemplate.opsForValue().set(KEY_PREFIX + email, code, TTL);
    }

    public boolean verify(String email, String code) {
        String key = KEY_PREFIX + email;
        String storedCode = redisTemplate.opsForValue().get(key);
        if (storedCode == null) {
            return false;
        }
        if (!storedCode.equals(code)) {
            return false;
        }
        redisTemplate.delete(key); // one-time use
        return true;
    }

    public void remove(String email) {
        redisTemplate.delete(KEY_PREFIX + email);
    }
}
