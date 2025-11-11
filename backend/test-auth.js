const fetch = require('node-fetch');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJlY2FjNDVmZi0xYzJjLTQ5MzctYmI2Ny1hYzdmMGIwZDJjYWIiLCJpYXQiOjE3NjI4MzE4NDgsImV4cCI6MTc2MjgzNTQ0OH0.8oAJuDkKNJEjTORgCRh8gLY9tc974wyr_cQQssya-zA';
const url = 'http://localhost:3000/api/v1/analytics/users/cm3y5x1w2000xxx/funnel';

fetch(url, {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
})
.then(response => {
  console.log('Status:', response.status);
  console.log('Status Text:', response.statusText);
  return response.text();
})
.then(text => {
  console.log('Response:', text);
})
.catch(error => {
  console.error('Error:', error.message);
});