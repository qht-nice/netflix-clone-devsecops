import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Container,
  Paper,
  Typography,
  Box,
  Button,
  TextField,
  Alert,
  CircularProgress,
} from '@mui/material';

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
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      navigate('/login');
      return;
    }

    fetch(`${API_URL}/api/users/me`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    })
      .then(res => {
        if (!res.ok) {
          throw new Error('Failed to fetch user data');
        }
        return res.json();
      })
      .then(data => {
        setUser(data.user);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
        // If token is invalid, redirect to login
        if (err.message.includes('Failed')) {
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          navigate('/login');
        }
      });
  }, [navigate]);

  if (loading) {
    return (
      <Container maxWidth="sm">
        <Box sx={{ mt: 8, display: 'flex', justifyContent: 'center' }}>
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  if (error && !user) {
    return (
      <Container maxWidth="sm">
        <Box sx={{ mt: 8 }}>
          <Alert severity="error">{error}</Alert>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 8 }}>
        <Paper elevation={3} sx={{ p: 4 }}>
          <Typography variant="h4" component="h1" gutterBottom align="center">
            Account Settings
          </Typography>

          {user && (
            <Box sx={{ mt: 3 }}>
              <TextField
                fullWidth
                label="Email"
                value={user.email}
                margin="normal"
                disabled
              />
              <TextField
                fullWidth
                label="Username"
                value={user.username || 'Not set'}
                margin="normal"
                disabled
              />
              <TextField
                fullWidth
                label="Member Since"
                value={new Date(user.created_at).toLocaleDateString()}
                margin="normal"
                disabled
              />
            </Box>
          )}

          <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              fullWidth
              onClick={() => navigate('/')}
            >
              Back to Home
            </Button>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
}

