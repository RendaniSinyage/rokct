const core = require('@actions/core');
const github = require('@actions/github');
const fetch = require('node-fetch');

async function run() {
  try {
    const repoToken = core.getInput('repo-token', { required: true });
    const apiEndpoint = core.getInput('rokct-api-endpoint', { required: true });
    const actionToken = core.getInput('rokct-action-token', { required: true });

    const { pull_request } = github.context.payload;

    if (!pull_request || pull_request.merged !== true) {
      core.info('This action runs only on merged pull requests.');
      return;
    }

    const prBody = pull_request.body || '';
    let sessionId = null;

    // Standard format: "Jules-Session: sessions/some-id-12345"
    const match = prBody.match(/Jules-Session:\s*(sessions\/[a-zA-Z0-9-]+)/);
    if (match && match[1]) {
      sessionId = match[1];
      core.info(`Found Jules session ID: ${sessionId}`);
    } else {
      core.info('No Jules session ID found in the PR body.');
      return;
    }

    core.info(`Sending notification to endpoint: ${apiEndpoint}`);

    const response = await fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-ROKCT-ACTION-TOKEN': actionToken,
      },
      body: JSON.stringify({ session_id: sessionId }),
    });

    if (!response.ok) {
      const responseBody = await response.text();
      throw new Error(`API call failed with status ${response.status}: ${responseBody}`);
    }

    const result = await response.json();
    core.info(`API Response: ${JSON.stringify(result)}`);
    core.setOutput('api-response', result);

  } catch (error) {
    core.setFailed(error.message);
  }
}

run();