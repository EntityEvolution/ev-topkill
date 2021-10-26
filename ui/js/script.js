const doc = document;
const maxNameLength = 10;
const closeKey = 'Backspace'

const scoreboard =  doc.getElementById('score');
const leaderboard = doc.getElementById('leaderboard');
window.addEventListener('load', () => {
    this.addEventListener('message', e => {
        if (e.data.action == 'showScoreboard') {
            if (window.getComputedStyle(scoreboard, null).display == 'flex') {
                return console.log('You need to close the other one first')
            };
            if (e.data.first) {
                updateData(e.data.first, '1');
            }
            if (e.data.second) {
                updateData(e.data.second, '2');
            }

            if (e.data.third) {
                updateData(e.data.third, '3');
            }
            doc.getElementById('leaderboard').style.display = 'flex';
        } else if (e.data.action == 'showScore') {
            if (window.getComputedStyle(leaderboard, null).display == 'flex') {
                return console.log('You need to close the other one first')
            };
            scoreboard.style.display = 'flex';
            updateScore(e.data.player);
        } 
    })

    doc.addEventListener('keyup', e => {
        if (e.key == closeKey) {
            fetchNUI('close');
            if (window.getComputedStyle(leaderboard, null).display == 'flex') {
                leaderboard.style.display = 'none';
            } else if (window.getComputedStyle(scoreboard, null).display == 'flex') {
                scoreboard.style.display = 'none';
            }
        }
    })
})

const updateData = (data, position) => {
    // Discord avatar check
    if (data.discord) {
        doc.getElementById(`discord-${position}`).src = data.discord;
    } else {
        doc.getElementById(`discord-${position}`).src = './default.png';
    }

    // Discord kills check
    if (data.kills.length > 7) {
        return console.log('Max kill number cannot be over 7!')
    }
    doc.getElementById(`kills-${position}`).textContent = data.kills;

    // Name length check
    if (data.name.length > maxNameLength) {
        doc.getElementById(`name-${position}`).textContent = `${position} - ${(data.name).slice(0, maxNameLength - 2) + '...'} - ${data.kills} kills`;
    } else {
        doc.getElementById(`name-${position}`).textContent = `${position} - ${data.name} - ${data.kills} kills`;
    }
}

const updateScore = data => {
    if (data.avatar) {
        doc.getElementById('personal-avatar').src = data.avatar;
    } else {
        doc.getElementById('personal-avatar').src = './default.png';
    }

    if (data.discord.length > maxNameLength) {
        doc.getElementById('personal-name').textContent = data.discord.slice(0, maxNameLength)
    } else {
        doc.getElementById('personal-name').textContent = data.discord;
    }

    if (data.kills.length > 7 || data.deaths.length > 7 || data.kd.length > 7) {
        return console.log('Max kill number cannot be over 7!')
    }
    doc.getElementById('personal-kills').textContent = data.kills;
    doc.getElementById('personal-deaths').textContent = data.deaths;
    doc.getElementById('personal-kd').textContent = data.kd;
}

const fetchNUI = async (cbname, data) => {
    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    };
    const resp = await fetch(`https://ev-topkill/${cbname}`, options);
    return await resp.json();
}