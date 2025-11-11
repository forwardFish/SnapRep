const fetch = require('node-fetch');

async function testLogin() {
  try {
    console.log('Testing user login...');

    const loginResponse = await fetch('http://localhost:3000/rest/v1/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'Test123456!'
      })
    });

    const loginData = await loginResponse.text();
    console.log('Login Status:', loginResponse.status);
    console.log('Login Response:', loginData);

    if (loginResponse.status === 200) {
      const parsed = JSON.parse(loginData);
      const token = parsed.data?.accessToken;

      if (token) {
        console.log('\n=== Testing API with fresh token ===');

        const apiResponse = await fetch('http://localhost:3000/api/v1/analytics/users/ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab/funnel', {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });

        const apiData = await apiResponse.text();
        console.log('API Status:', apiResponse.status);
        console.log('API Response:', apiData);
      } else {
        console.log('No access token found in login response');
      }
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testLogin();