const fetch = require('node-fetch');

async function testRegisterAndAuth() {
  try {
    console.log('Testing user registration and authentication...');

    // Generate random email to avoid conflicts
    const randomEmail = `test${Date.now()}@example.com`;

    console.log(`Registering user: ${randomEmail}`);

    const registerResponse = await fetch('http://localhost:3000/rest/v1/auth/register', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: randomEmail,
        password: 'Test123456!',
        name: 'Test User'
      })
    });

    const registerData = await registerResponse.text();
    console.log('Register Status:', registerResponse.status);
    console.log('Register Response:', registerData);

    if (registerResponse.status === 200 || registerResponse.status === 201) {
      const parsed = JSON.parse(registerData);
      const token = parsed.data?.accessToken;

      if (token) {
        console.log('\n=== Testing API with fresh token ===');
        console.log('Token:', token.substring(0, 50) + '...');

        const apiResponse = await fetch('http://localhost:3000/api/v1/analytics/users/ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab/funnel', {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });

        const apiData = await apiResponse.text();
        console.log('API Status:', apiResponse.status);
        console.log('API Response:', apiData);

        if (apiResponse.status === 200) {
          console.log('\n✅ AUTHENTICATION FIX SUCCESSFUL!');
        } else {
          console.log('\n❌ Authentication still failing');
        }
      } else {
        console.log('No access token found in registration response');
      }
    } else {
      console.log('Registration failed');
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testRegisterAndAuth();