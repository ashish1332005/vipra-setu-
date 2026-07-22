const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const saveImageUpload = (imageFile, options = {}) => {
  const {
    folder = 'images', label = 'Image', maxSizeMb = 5,
    allowedTypes = { 'image/jpeg': '.jpg', 'image/png': '.png', 'image/webp': '.webp' },
  } = options;
  const { name = 'image', dataUrl } = imageFile || {};
  const match = typeof dataUrl === 'string' && dataUrl.match(/^data:([\w/+.-]+);base64,([A-Za-z0-9+/=\r\n]+)$/);
  if (!match) throw uploadError(`Invalid ${label.toLowerCase()} upload`);

  const mimeType = match[1].toLowerCase();
  const extension = allowedTypes[mimeType];
  if (!extension) throw uploadError(`Unsupported ${label.toLowerCase()} file type`);

  const buffer = Buffer.from(match[2], 'base64');
  if (!buffer.length || buffer.length > maxSizeMb * 1024 * 1024) {
    throw uploadError(`${label} must be ${maxSizeMb}MB or smaller`);
  }
  if (!hasExpectedSignature(buffer, mimeType)) {
    throw uploadError(`${label} content does not match its declared file type`);
  }

  const uploadDir = path.join(__dirname, '..', 'uploads', folder);
  fs.mkdirSync(uploadDir, { recursive: true, mode: 0o750 });
  const safeBaseName = path.basename(name).replace(/\.[^.]+$/, '')
    .replace(/[^a-z0-9-]/gi, '-').replace(/-+/g, '-').slice(0, 60).toLowerCase() || 'file';
  const filename = `${crypto.randomUUID()}-${safeBaseName}${extension}`;
  const destination = path.join(uploadDir, filename);
  fs.writeFileSync(destination, buffer, { mode: 0o640, flag: 'wx' });
  return `/uploads/${folder}/${filename}`;
};

const hasExpectedSignature = (buffer, mimeType) => {
  if (mimeType === 'image/jpeg') return buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  if (mimeType === 'image/png') return buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]));
  if (mimeType === 'image/webp') return buffer.length >= 12 && buffer.toString('ascii', 0, 4) === 'RIFF' && buffer.toString('ascii', 8, 12) === 'WEBP';
  if (mimeType === 'application/pdf') return buffer.length >= 5 && buffer.toString('ascii', 0, 5) === '%PDF-';
  return false;
};

const uploadError = (message) => {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
};

module.exports = saveImageUpload;