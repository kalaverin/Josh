if [ "$SSH_AGENT_PID" -gt 0 ]; then
    kill $SSH_AGENT_PID 2>/dev/null
fi
