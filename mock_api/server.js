const jsonServer = require('json-server')
const server = jsonServer.create()
const router = jsonServer.router('db.json')
const middlewares = jsonServer.defaults()

// 1. CRITICAL: Must use bodyParser FIRST
server.use(jsonServer.bodyParser)

// 2. Custom login route - MUST come before jsonServer defaults
server.post('/auth/login', (req, res) => {
  console.log('\nReceived login request:', req.body)
  
  if (req.body?.email === 'john@example.com' && req.body?.password === 'any') {
    return res.json({
      success: true,
      token: 'mock_jwt_token_123',
      user: { id: 1, email: 'john@example.com' }
    })
  }
  
  res.status(401).json({ 
    success: false,
    error: 'Invalid credentials' 
  })
})

// 3. Only NOW apply default middleware
server.use(middlewares)

// 4. Add request logging
server.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.path}`)
  next()
})

// 5. Start server with clear output
const PORT = 8000
server.listen(PORT, () => {
  console.log('\n\x1b[32m✔ Server running on:\x1b[0m')
  console.log(`- Local:   http://localhost:${PORT}`)
  console.log(`- Network: http://${require('ip').address()}:${PORT}`)
  console.log('\n\x1b[36mTest login with:\x1b[0m')
  console.log(`curl -X POST http://localhost:${PORT}/auth/login \\\n  -H "Content-Type: application/json" \\\n  -d '{"email":"john@example.com","password":"any"}'`)
})