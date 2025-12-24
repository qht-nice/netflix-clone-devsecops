import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  Alert,
} from '@mui/material';

// Construct API URL from current host (works in both dev and production)
const getApiUrl = () => {
  const envUrl = import.meta.env.VITE_APP_API_URL;
  if (envUrl && !envUrl.includes('localhost') && !envUrl.includes('netflix-backend')) {
    return envUrl;
  }
  // Use same host as frontend but port 30008 (NodePort for backend)
  const host = globalThis?.location?.hostname || 'localhost';
  return `http://${host}:30008`;
};
const API_URL = getApiUrl();

export function Component() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  // Debug: Log error state changes
  useEffect(() => {
    if (error) {
      console.log('Error state changed to:', error);
    }
  }, [error]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    
    // Client-side validation
    if (!email || !email.includes('@')) {
      setError('Please enter a valid email address');
      return;
    }
    
    if (!password) {
      setError('Password is required');
      return;
    }
    
    setLoading(true);

    try {
      const response = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      // Check response status first
      if (!response.ok) {
        let errorData;
        try {
          errorData = await response.json();
        } catch (parseError) {
          // If response is not JSON, use status text
          throw new Error(`Server error: ${response.status} ${response.statusText}`);
        }
        
        // Handle validation errors (400 status with errors array)
        if (errorData.errors && Array.isArray(errorData.errors)) {
          const validationError = errorData.errors[0];
          if (validationError.path === 'email') {
            throw new Error('Please enter a valid email address');
          } else if (validationError.path === 'password') {
            throw new Error('Password is required');
          } else {
            throw new Error(validationError.msg || 'Invalid input');
          }
        }
        
        // Handle specific error messages
        const errorMessage = errorData.message || errorData.error || `Login failed (${response.status})`;
        console.error('Login error response:', errorMessage, errorData, 'Status:', response.status);
        throw new Error(errorMessage);
      }

      // Parse successful response
      const data = await response.json();

      // Store token
      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));

      // Redirect to home
      navigate('/');
    } catch (err: any) {
      // Display user-friendly error messages
      let errorMessage = 'An error occurred. Please try again.';
      
      console.log('Catch block - err:', err);
      console.log('Catch block - err.message:', err.message);
      
      if (err.message) {
        if (err.message.includes('Invalid credentials') || err.message.includes('401')) {
          errorMessage = 'Invalid email or password';
        } else if (err.message.includes('Network') || err.message.includes('Failed to fetch')) {
          errorMessage = 'Unable to connect to the server. Please check your connection.';
        } else {
          errorMessage = err.message;
        }
      }
      
      console.log('Setting error message to:', errorMessage);
      setError(errorMessage);
      console.log('Error state should be set to:', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 8 }}>
        <Paper elevation={3} sx={{ p: 4 }}>
          <Typography variant="h4" component="h1" gutterBottom align="center">
            Sign In
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }} data-testid="login-error">
              {error}
            </Alert>
          )}

          <form onSubmit={handleSubmit} noValidate>
            <TextField
              fullWidth
              label="Email"
              type="text"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              margin="normal"
              required
              autoComplete="email"
              error={error.includes('email') || error.includes('Email')}
            />
            <TextField
              fullWidth
              label="Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              required
              autoComplete="current-password"
            />
            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={loading}
            >
              {loading ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>

          <Typography variant="body2" align="center">
            Don't have an account?{' '}
            <Link to="/register" style={{ textDecoration: 'none' }}>
              Sign up
            </Link>
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
}

