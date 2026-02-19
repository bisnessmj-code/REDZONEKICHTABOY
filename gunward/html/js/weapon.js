(function() {
    const container = document.getElementById('weapon-shop');
    const weaponList = document.getElementById('weapon-list');
    const balanceEl = document.getElementById('wshop-balance');

    let weapons = [];
    let selectableItems = [];
    let balance = 0;
    let selectedIndex = 0;
    let isOpen = false;

    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.action === 'openWeaponShop') {
            weapons = data.weapons || [];
            balance = data.balance || 0;
            selectedIndex = 0;
            isOpen = true;
            render();
            container.classList.remove('hidden');
        }

        if (data.action === 'closeWeaponShop') {
            closeShop();
        }

        if (data.action === 'updateBalance') {
            balance = data.balance || 0;
            balanceEl.textContent = '$' + balance.toLocaleString();
        }
    });

    function render() {
        balanceEl.textContent = '$' + balance.toLocaleString();
        weaponList.innerHTML = '';
        selectableItems = [];

        let currentCategory = '';
        let itemIndex = 0;

        weapons.forEach(function(wep) {
            // Category header
            if (wep.category !== currentCategory) {
                currentCategory = wep.category;
                const catHeader = document.createElement('div');
                catHeader.className = 'wshop-category';
                catHeader.textContent = wep.category;
                weaponList.appendChild(catHeader);
            }

            const item = document.createElement('div');
            item.className = 'wshop-item' + (itemIndex === selectedIndex ? ' selected' : '');

            const name = document.createElement('span');
            name.className = 'wshop-name';
            name.textContent = wep.label;

            const price = document.createElement('span');
            price.className = 'wshop-price';

            if (wep.price === 0) {
                price.textContent = 'GRATUIT';
                price.classList.add('free');
            } else {
                price.textContent = '$' + wep.price.toLocaleString();
                if (balance >= wep.price) {
                    price.classList.add('affordable');
                } else {
                    price.classList.add('expensive');
                }
            }

            item.appendChild(name);
            item.appendChild(price);

            const idx = itemIndex;
            item.addEventListener('click', function() {
                selectedIndex = idx;
                updateSelection();
                purchase();
            });

            item.addEventListener('mouseenter', function() {
                selectedIndex = idx;
                updateSelection();
            });

            weaponList.appendChild(item);
            selectableItems.push(item);
            itemIndex++;
        });
    }

    function updateSelection() {
        selectableItems.forEach(function(item, i) {
            item.classList.toggle('selected', i === selectedIndex);
        });

        const selected = selectableItems[selectedIndex];
        if (selected) {
            selected.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
    }

    function purchase() {
        if (!weapons[selectedIndex]) return;
        const wep = weapons[selectedIndex];

        fetch('https://gunward/buyWeapon', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ weapon: wep.weapon, price: wep.price })
        });
    }

    function closeShop() {
        if (!isOpen) return;
        isOpen = false;
        container.classList.add('hidden');
        fetch('https://gunward/closeWeaponShop', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }

    document.addEventListener('keydown', function(e) {
        if (!isOpen) return;

        if (e.key === 'Escape') {
            e.preventDefault();
            closeShop();
            return;
        }

        if (e.key === 'ArrowUp') {
            e.preventDefault();
            selectedIndex = Math.max(0, selectedIndex - 1);
            updateSelection();
        }

        if (e.key === 'ArrowDown') {
            e.preventDefault();
            selectedIndex = Math.min(selectableItems.length - 1, selectedIndex + 1);
            updateSelection();
        }

        if (e.key === 'Enter') {
            e.preventDefault();
            purchase();
        }
    });
})();

// ===================== WEAPON SELL SHOP =====================
(function() {
    const container = document.getElementById('weapon-sell');
    const sellList  = document.getElementById('sell-list');
    const balanceEl = document.getElementById('wsell-balance');

    let weapons = [];
    let selectedIndex = 0;
    let balance = 0;
    let isOpen = false;

    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.action === 'openWeaponSell') {
            weapons = data.weapons || [];
            balance = data.balance || 0;
            selectedIndex = 0;
            isOpen = true;
            render();
            container.classList.remove('hidden');
        }

        if (data.action === 'closeWeaponSell') {
            closeSell();
        }
    });

    function render() {
        balanceEl.textContent = '$' + balance.toLocaleString();
        sellList.innerHTML = '';

        if (weapons.length === 0) {
            const empty = document.createElement('div');
            empty.className = 'wsell-empty';
            empty.textContent = 'Aucune arme à revendre';
            sellList.appendChild(empty);
            return;
        }

        weapons.forEach(function(wep, idx) {
            const item = document.createElement('div');
            item.className = 'wsell-item' + (idx === selectedIndex ? ' selected' : '');

            const name = document.createElement('span');
            name.className = 'wsell-name';
            name.textContent = wep.label;

            const price = document.createElement('span');
            price.className = 'wsell-price';
            if (wep.sellPrice === 0) {
                price.textContent = 'SANS VALEUR';
                price.classList.add('free');
            } else {
                price.textContent = '+$' + wep.sellPrice.toLocaleString();
            }

            item.appendChild(name);
            item.appendChild(price);

            item.addEventListener('click', function() {
                selectedIndex = idx;
                updateSelection();
                sell();
            });

            item.addEventListener('mouseenter', function() {
                selectedIndex = idx;
                updateSelection();
            });

            sellList.appendChild(item);
        });
    }

    function updateSelection() {
        const items = sellList.querySelectorAll('.wsell-item');
        items.forEach(function(item, i) {
            item.classList.toggle('selected', i === selectedIndex);
        });
        const selected = items[selectedIndex];
        if (selected) selected.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }

    function sell() {
        if (!weapons[selectedIndex]) return;
        const wep = weapons[selectedIndex];

        fetch('https://gunward/sellWeapon', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ weapon: wep.weapon })
        });
    }

    function closeSell() {
        if (!isOpen) return;
        isOpen = false;
        container.classList.add('hidden');
        fetch('https://gunward/closeWeaponSell', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }

    document.addEventListener('keydown', function(e) {
        if (!isOpen) return;

        if (e.key === 'Escape') {
            e.preventDefault();
            closeSell();
            return;
        }

        if (e.key === 'ArrowUp') {
            e.preventDefault();
            selectedIndex = Math.max(0, selectedIndex - 1);
            updateSelection();
        }

        if (e.key === 'ArrowDown') {
            e.preventDefault();
            selectedIndex = Math.min(weapons.length - 1, selectedIndex + 1);
            updateSelection();
        }

        if (e.key === 'Enter') {
            e.preventDefault();
            sell();
        }
    });
})();
