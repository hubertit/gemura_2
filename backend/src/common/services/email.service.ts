import { Injectable, Logger } from '@nestjs/common';
import nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor() {
    // Initialize email transporter
    // Using environment variables or defaults
    const smtpConfig = {
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
      auth: {
        user: process.env.SMTP_USER || process.env.EMAIL_USER,
        pass: process.env.SMTP_PASS || process.env.EMAIL_PASSWORD,
      },
    };

    // Only create transporter if credentials are provided
    if (smtpConfig.auth.user && smtpConfig.auth.pass) {
      try {
        this.transporter = nodemailer.createTransport(smtpConfig);
        this.logger.log('Email transporter initialized');
      } catch (error) {
        this.logger.warn('Failed to initialize email transporter', error);
      }
    } else {
      this.logger.warn('Email credentials not configured. Email sending will be disabled.');
    }
  }

  /**
   * Send email
   * @param to Recipient email address
   * @param subject Email subject
   * @param text Plain text email content
   * @param html Optional HTML email content
   * @returns Promise<boolean> - true if sent successfully, false otherwise
   */
  async sendEmail(
    to: string,
    subject: string,
    text: string,
    html?: string,
  ): Promise<boolean> {
    if (!this.transporter) {
      this.logger.warn('Email transporter not configured. Cannot send email.');
      return false;
    }

    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM || 'noreply@gemura.rw',
        to: to,
        subject: subject,
        text: text,
        html: html || text.replace(/\n/g, '<br>'),
      };

      const info = await this.transporter.sendMail(mailOptions);
      this.logger.log(`Email sent successfully to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      this.logger.error(`Email sending error to ${to}: ${error.message}`, error.stack);
      return false;
    }
  }

  /**
   * Send password reset code email
   * @param to Recipient email address
   * @param resetCode 6-digit reset code
   * @returns Promise<boolean>
   */
  async sendPasswordResetCode(to: string, resetCode: string): Promise<boolean> {
    const subject = 'Password Reset Code - Gemura';
    const text = `Your password reset code is: ${resetCode}\n\nThis code will expire in 15 minutes.\n\nIf you didn't request this, please ignore this message.`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">Password Reset Code</h2>
        <p>Your password reset code is:</p>
        <div style="background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
          ${resetCode}
        </div>
        <p>This code will expire in 15 minutes.</p>
        <p style="color: #666; font-size: 12px;">If you didn't request this, please ignore this message.</p>
      </div>
    `;

    return this.sendEmail(to, subject, text, html);
  }
}
