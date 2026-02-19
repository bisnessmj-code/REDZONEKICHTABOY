(function() {
    const container = document.getElementById('vehicle-shop');
    const vehicleList = document.getElementById('vehicle-list');
    const balanceEl = document.getElementById('vshop-balance');

    let vehicles = [];
    let balance = 0;
    let selectedIndex = 0;
    let isOpen = false;

    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.action === 'openVehicleShop') {
            vehicles = data.vehicles || [];
            balance = data.balance || 0;
            selectedIndex = 0;
            isOpen = true;
            render();
            container.classList.remove('hidden');
        }

        if (data.action === 'closeVehicleShop') {
            closeShop();
        }

        if (data.action === 'updateBalance') {
            balance = data.balance || 0;
            balanceEl.textContent = '$' + balance.toLocaleString();
        }
    });

    function render() {
        balanceEl.textContent = '$' + balance.toLocaleString();
        vehicleList.innerHTML = '';

        vehicles.forEach(function(veh, index) {
            const item = document.createElement('div');
            item.className = 'vshop-item' + (index === selectedIndex ? ' selected' : '');

            const name = document.createElement('span');
            name.className = 'vshop-name';
            name.textContent = veh.label;

            const price = document.createElement('span');
            price.className = 'vshop-price';

            if (veh.price === 0) {
                price.textContent = 'GRATUIT';
                price.classList.add('free');
            } else {
                price.textContent = '$' + veh.price.toLocaleString();
                if (balance >= veh.price) {
                    price.classList.add('affordable');
                } else {
                    price.classList.add('expensive');
                }
            }

            item.appendChild(name);
            item.appendChild(price);

            item.addEventListener('click', function() {
                selectedIndex = index;
                updateSelection();
                purchase();
            });

            item.addEventListener('mouseenter', function() {
                selectedIndex = index;
                updateSelection();
            });

            vehicleList.appendChild(item);
        });
    }

    function updateSelection() {
        const items = vehicleList.querySelectorAll('.vshop-item');
        items.forEach(function(item, i) {
            item.classList.toggle('selected', i === selectedIndex);
        });

        const selected = items[selectedIndex];
        if (selected) {
            selected.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }
    }

    function purchase() {
        if (!vehicles[selectedIndex]) return;
        const veh = vehicles[selectedIndex];

        fetch('https://gunward/buyVehicle', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: veh.model, price: veh.price })
        });
    }

    function closeShop() {
        if (!isOpen) return;
        isOpen = false;
        container.classList.add('hidden');
        fetch('https://gunward/closeVehicleShop', {
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
            selectedIndex = Math.min(vehicles.length - 1, selectedIndex + 1);
            updateSelection();
        }

        if (e.key === 'Enter') {
            e.preventDefault();
            purchase();
        }
    });
})();
