import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './index.css';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error("FreeWatch Admin Panel Runtime Error:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-[#F8FAFC] flex items-center justify-center p-6 font-sans">
          <div className="bg-white rounded-2xl p-8 border border-slate-200 shadow-xl max-w-lg w-full text-center space-y-4">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-[#00E676] to-[#00C853] flex items-center justify-center mx-auto shadow-md shadow-[#00E676]/30">
              <span className="font-black text-black text-xl">FW</span>
            </div>
            <h2 className="text-xl font-bold text-slate-900">FreeWatch Admin Console Notice</h2>
            <p className="text-xs text-slate-500">
              A temporary runtime issue occurred while loading this view. You can reload the dashboard safely.
            </p>
            {this.state.error && (
              <pre className="p-3 bg-slate-50 border border-slate-200 rounded-xl text-left text-[11px] text-rose-600 font-mono overflow-x-auto max-h-32">
                {this.state.error.toString()}
              </pre>
            )}
            <button
              onClick={() => window.location.reload()}
              className="px-6 py-2.5 bg-[#00E676] hover:bg-[#00C853] text-black font-extrabold rounded-xl text-xs transition-all shadow-sm shadow-[#00E676]/25"
            >
              Reload Dashboard
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </React.StrictMode>
);

