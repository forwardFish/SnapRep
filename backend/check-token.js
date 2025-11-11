// JWT token expiration check
const jwt = require('jsonwebtoken');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJlY2FjNDVmZi0xYzJjLTQ5MzctYmI2Ny1hYzdmMGIwZDJjYWIiLCJpYXQiOjE3MzEyODU4NDgsImV4cCI6MTczMTI4OTQ0OH0.8oAJuDkKNJEjTORgCRh8gLY9tc974wyr_cQQssya-zA';

console.log('Current time:', Math.floor(Date.now() / 1000));
console.log('Current time readable:', new Date().toISOString());

try {
  const decoded = jwt.decode(token);
  console.log('Token payload:', decoded);
  console.log('Token issued at:', new Date(decoded.iat * 1000).toISOString());
  console.log('Token expires at:', new Date(decoded.exp * 1000).toISOString());

  const now = Math.floor(Date.now() / 1000);
  if (decoded.exp < now) {
    console.log('TOKEN IS EXPIRED!');
  } else {
    console.log('Token is valid');
  }
} catch (error) {
  console.error('Token decode error:', error);
}