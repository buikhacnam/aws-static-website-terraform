import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'

function App() {
  const [count, setCount] = useState(0)
  const [deployTime] = useState(new Date().toLocaleString())

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>🚀 Casey.click</h1>
      <h2>Static Website Hosting with AWS</h2>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          Clicks: {count} 🎯
        </button>
        <p>
          <strong>✅ Live deployment successful!</strong><br/>
          This React app is hosted on <code>AWS S3</code> with <code>CloudFront CDN</code>
        </p>
        <div style={{ 
          background: '#1a1a1a', 
          padding: '1rem', 
          borderRadius: '8px', 
          margin: '1rem 0',
          textAlign: 'left',
          color: 'white'
        }}>
          <h3>🏗️ Infrastructure:</h3>
          <ul style={{ textAlign: 'left', margin: 0 }}>
            <li>🪣 <strong>S3:</strong> Private bucket hosting</li>
            <li>⚡ <strong>CloudFront:</strong> Global CDN distribution</li>
            <li>🔒 <strong>SSL:</strong> Free ACM certificates</li>
            <li>🌐 <strong>Route53:</strong> DNS management</li>
            <li>🔄 <strong>Redirect:</strong> casey.click → www.casey.click</li>
          </ul>
        </div>
        <p style={{ 
          background: '#0d7377', 
          color: 'white', 
          padding: '0.5rem', 
          borderRadius: '4px'
        }}>
          🕐 <strong>Deployed:</strong> {deployTime}
        </p>
      </div>
      <p className="read-the-docs">
        🎉 Your static website is now live at <strong>casey.click</strong> & <strong>www.casey.click</strong>
      </p>
    </>
  )
}

export default App
