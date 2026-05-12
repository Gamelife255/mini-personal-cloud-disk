package com.disk.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.Random;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Autowired
    private com.disk.util.VerificationCodeStore codeStore;

    public String sendVerificationCode(String toEmail) {
        String code = generateCode();
        codeStore.save(toEmail, code);
        String content = buildEmailContent(code, "注册账号");
        sendHtmlMailAsync(toEmail, "【个人云盘】邮箱验证码", content);
        return code;
    }

    public String sendPasswordResetCode(String toEmail) {
        String code = generateCode();
        codeStore.save(toEmail, code);
        String content = buildEmailContent(code, "重置密码");
        sendHtmlMailAsync(toEmail, "【个人云盘】密码重置验证码", content);
        return code;
    }

    public boolean verifyCode(String email, String code) {
        return codeStore.verify(email, code);
    }

    private String generateCode() {
        return String.format("%06d", new Random().nextInt(1000000));
    }

    private String buildEmailContent(String code, String purpose) {
        return """
                <div style="max-width:480px;margin:0 auto;padding:32px;font-family:sans-serif;background:#f9fafb;border-radius:12px">
                    <h2 style="color:#409EFF;margin-top:0">个人云盘</h2>
                    <p>您正在%s，验证码如下：</p>
                    <div style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#333;padding:16px 24px;background:#fff;border-radius:8px;text-align:center;margin:16px 0">
                        %s
                    </div>
                    <p style="color:#909399;font-size:13px">验证码 15 分钟内有效，请勿泄露给他人。</p>
                </div>
                """.formatted(purpose, code);
    }

    @Async
    public void sendHtmlMailAsync(String to, String subject, String html) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, false, "UTF-8");
            helper.setFrom("2055126913@qq.com");
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
        } catch (MessagingException e) {
            throw new RuntimeException("邮件发送失败: " + e.getMessage());
        }
    }
}
