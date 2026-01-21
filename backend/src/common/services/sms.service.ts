import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import * as https from 'https';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Send SMS via Mista API
   * @param recipient Phone number (with country code, e.g., 250788123456)
   * @param message SMS message content
   * @returns Promise<boolean> - true if sent successfully, false otherwise
   */
  async sendSMS(recipient: string, message: string): Promise<boolean> {
    try {
      // Get Mista SMS API key from database
      // Using name field to identify Mista API key (since key_type doesn't exist in schema)
      const apiKeyRecord = await this.prisma.apiKey.findFirst({
        where: {
          name: {
            contains: 'mista',
            mode: 'insensitive',
          },
          is_active: true,
        },
        orderBy: {
          created_at: 'desc',
        },
      });

      if (!apiKeyRecord) {
        this.logger.warn('Mista SMS API key not found or inactive');
        return false;
      }

      const apiKey = apiKeyRecord.key;

      // Prepare SMS data
      const smsData = {
        recipient: recipient,
        sender_id: 'E-Notifier',
        type: 'plain',
        message: message,
      };

      // Send SMS via Mista API using https module
      return new Promise<boolean>((resolve) => {
        const postData = JSON.stringify(smsData);

        const options = {
          hostname: 'api.mista.io',
          port: 443,
          path: '/sms',
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData),
          },
          timeout: 30000,
        };

        const req = https.request(options, (res) => {
          let responseData = '';

          res.on('data', (chunk) => {
            responseData += chunk;
          });

          res.on('end', () => {
            if (res.statusCode === 200) {
              try {
                const parsed = JSON.parse(responseData);
                if (parsed.status === 'success') {
                  this.logger.log(`SMS sent successfully to ${recipient}`);
                  resolve(true);
                } else {
                  this.logger.error(`SMS API returned non-success status: ${responseData}`);
                  resolve(false);
                }
              } catch (error) {
                this.logger.error(`Failed to parse SMS API response: ${responseData}`);
                resolve(false);
              }
            } else {
              this.logger.error(`SMS sending failed: HTTP ${res.statusCode}, Response: ${responseData}`);
              resolve(false);
            }
          });
        });

        req.on('error', (error) => {
          this.logger.error(`SMS sending error: ${error.message}`, error.stack);
          resolve(false);
        });

        req.on('timeout', () => {
          req.destroy();
          this.logger.error('SMS sending timeout');
          resolve(false);
        });

        req.write(postData);
        req.end();
      });
    } catch (error) {
      this.logger.error(`SMS sending error: ${error.message}`, error.stack);
      return false;
    }
  }
}
