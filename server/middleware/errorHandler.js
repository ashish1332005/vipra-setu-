const errorHandler = (error, req, res, next) => {
  let statusCode = error.statusCode || (res.statusCode !== 200 ? res.statusCode : 500);
  if (error.type === 'entity.too.large') statusCode = 413;
  if (error.type === 'entity.parse.failed') statusCode = 400;
  if (error.name === 'CastError' || error.name === 'ValidationError') statusCode = 400;
  if (error.code === 11000) statusCode = 409;

  const production = process.env.NODE_ENV === 'production';
  const safeClientError = statusCode >= 400 && statusCode < 500;
  const message = production && !safeClientError
    ? 'Internal server error'
    : formatErrorMessage(error, statusCode);

  if (!production && statusCode >= 500) console.error(error);
  res.status(statusCode).json({ message });
};

const formatErrorMessage = (error, statusCode) => {
  if (statusCode === 413) return 'Request payload is too large';
  if (statusCode === 400 && error.type === 'entity.parse.failed') return 'Invalid JSON payload';
  if (error.name === 'CastError') return 'Invalid resource identifier';
  if (error.name === 'ValidationError') return 'Request validation failed';
  if (error.code === 11000) return 'A record with those details already exists';
  return error.message || 'Server error';
};

module.exports = errorHandler;