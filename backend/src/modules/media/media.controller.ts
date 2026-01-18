import { Controller, Get, Param, Res, HttpException, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import * as https from 'https';
import * as http from 'http';

@Controller('media')
export class MediaController {
  private readonly OLD_SERVER_BASE_URL = 'https://www.kigalitoday.com';

  @Get('*')
  async proxyMedia(@Param('0') path: string, @Res() res: Response) {
    if (!path) {
      throw new HttpException('Media path is required', HttpStatus.BAD_REQUEST);
    }

    // Remove leading slash if present
    const cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // Construct the full URL to the old server
    // Path format: IMG/jpg/444-12.jpg -> https://www.kigalitoday.com/IMG/jpg/444-12.jpg
    const targetUrl = `${this.OLD_SERVER_BASE_URL}/${cleanPath}`;

    try {
      // Use https module to fetch from the old server
      https.get(targetUrl, (proxyRes) => {
        // Set appropriate headers
        res.setHeader('Content-Type', proxyRes.headers['content-type'] || 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year
        res.setHeader('Access-Control-Allow-Origin', '*');
        
        // Handle redirects
        if (proxyRes.statusCode === 301 || proxyRes.statusCode === 302) {
          const location = proxyRes.headers.location;
          if (location) {
            return res.redirect(proxyRes.statusCode, location);
          }
        }

        // If successful, pipe the response
        if (proxyRes.statusCode === 200) {
          proxyRes.pipe(res);
        } else {
          res.status(proxyRes.statusCode || 500).json({
            code: proxyRes.statusCode || 500,
            status: 'error',
            message: `Failed to fetch media from old server: ${proxyRes.statusCode}`,
          });
        }
      }).on('error', (error) => {
        console.error('Media proxy error:', error);
        res.status(HttpStatus.BAD_GATEWAY).json({
          code: 502,
          status: 'error',
          message: `Failed to proxy media: ${error.message}`,
        });
      });
    } catch (error) {
      console.error('Media proxy exception:', error);
      throw new HttpException(
        `Failed to proxy media: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
